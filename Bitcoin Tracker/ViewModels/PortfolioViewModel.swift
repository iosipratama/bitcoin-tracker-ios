import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class PortfolioViewModel {
    private enum Key {
        static let currency = "selectedCurrency"
        static let showFiat = "showFiat"
    }

    /// Blockstream's public API throttles aggressive clients, and a throttled
    /// response surfaces as an error badge on a wallet row. Stay well under.
    private static let maxConcurrentFetches = 4

    var isLoading = false
    var priceError: String?
    var prices: [String: Double] = [:]

    var selectedCurrency: FiatCurrency {
        didSet {
            guard selectedCurrency != oldValue else { return }
            UserDefaults.standard.set(selectedCurrency.rawValue, forKey: Key.currency)
        }
    }

    var showFiat: Bool {
        didSet {
            guard showFiat != oldValue else { return }
            UserDefaults.standard.set(showFiat, forKey: Key.showFiat)
        }
    }

    init() {
        let defaults = UserDefaults.standard
        selectedCurrency = defaults.string(forKey: Key.currency)
            .flatMap(FiatCurrency.init(rawValue:)) ?? .usd
        showFiat = defaults.object(forKey: Key.showFiat) as? Bool ?? true
    }

    var currentPrice: Double {
        prices[selectedCurrency.apiKey] ?? 0
    }

    /// False when the price fetch failed or hasn't landed yet. Without this check a
    /// failed fetch renders every holding as "$0.00", which reads as "your bitcoin is gone".
    var isFiatAvailable: Bool {
        currentPrice > 0
    }

    var showsFiatValues: Bool {
        showFiat && isFiatAvailable
    }

    func fiatValue(btc: Double) -> Double {
        btc * currentPrice
    }

    func formattedBTC(_ value: Double) -> String {
        value.btcDisplay
    }

    /// Delegates fraction digits to the currency itself — JPY, KRW and VND have
    /// none, so a hardcoded two would have rendered "¥1,234.00". Above four
    /// figures the decimals are dropped entirely; on a rupiah balance they are
    /// only noise.
    func formattedFiat(_ value: Double) -> String {
        let style = FloatingPointFormatStyle<Double>.Currency(code: selectedCurrency.rawValue)
        return abs(value) >= 10_000
            ? value.formatted(style.precision(.fractionLength(0)))
            : value.formatted(style)
    }

    func refreshPrices() async {
        do {
            prices = try await PriceService.shared.fetchPrices()
            priceError = nil
        } catch {
            priceError = error.localizedDescription
        }
    }

    func refreshBalances(wallets: [Wallet]) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        await refreshPrices()

        let addresses = wallets.flatMap(\.addresses)
        let unique = Array(Set(addresses.map(\.address)))
        guard !unique.isEmpty else { return }

        let results = await Self.fetchBalances(for: unique)

        for address in addresses {
            switch results[address.address] {
            case .balance(let satoshis):
                address.balanceSatoshis = satoshis
                address.lastUpdated = .now
                address.fetchError = nil
            case .failure(let message):
                address.fetchError = message
            case nil:
                break
            }
        }
    }

    private enum BalanceFetch: Sendable {
        case balance(Int64)
        case failure(String)
    }

    /// Runs off the main actor over plain strings, keeping SwiftData models on the
    /// main actor and capping how many requests are in flight at once.
    private nonisolated static func fetchBalances(for addresses: [String]) async -> [String: BalanceFetch] {
        await withTaskGroup(of: (String, BalanceFetch).self) { group in
            var results: [String: BalanceFetch] = [:]
            var next = 0

            func enqueue() {
                guard next < addresses.count else { return }
                let address = addresses[next]
                next += 1
                group.addTask {
                    do {
                        let satoshis = try await BitcoinAPIService.shared.fetchBalance(for: address)
                        return (address, .balance(satoshis))
                    } catch {
                        return (address, .failure(error.localizedDescription))
                    }
                }
            }

            for _ in 0..<min(maxConcurrentFetches, addresses.count) { enqueue() }

            while let (address, result) = await group.next() {
                results[address] = result
                enqueue()
            }

            return results
        }
    }
}
