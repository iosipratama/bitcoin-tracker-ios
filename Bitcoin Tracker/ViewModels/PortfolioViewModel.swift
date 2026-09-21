import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class PortfolioViewModel {
    private enum Key {
        static let currency = "selectedCurrency"
        static let showFiat = "showFiat"
        static let showSatoshi = "showSatoshi"
        static let flipToHide = "flipToHideBalance"
    }

    /// Public explorer APIs throttle aggressive clients, and a throttled response
    /// surfaces as an error badge on a wallet row. Stay well under.
    private static let maxConcurrentFetches = 4

    var isLoading = false
    var priceError: String?
    /// True when the last refresh reached nothing. Drives a quiet staleness
    /// marker beside the "Updated" stamp — the reason itself is not shown,
    /// because a stale figure is still a true one.
    var lastRefreshFailed = false

    /// How long to wait before the one quiet retry. Most transport failures are
    /// transient, so the calmest fix is the one nobody sees.
    private static let retryDelay = Duration.seconds(3)
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

    /// Denominate in satoshis rather than BTC. Below a whole coin a sats figure
    /// is easier to read than eight decimal places.
    var showSatoshi: Bool {
        didSet {
            guard showSatoshi != oldValue else { return }
            UserDefaults.standard.set(showSatoshi, forKey: Key.showSatoshi)
        }
    }

    /// Turn the phone face down and the figures become asterisks; turn it face
    /// down again to bring them back. Off by default: a balance that vanishes
    /// unasked reads as a bug.
    var flipToHideBalance: Bool {
        didSet {
            guard flipToHideBalance != oldValue else { return }
            UserDefaults.standard.set(flipToHideBalance, forKey: Key.flipToHide)

            if flipToHideBalance {
                flipDetector.start()
            } else {
                flipDetector.stop()
                balancesHidden = false
            }
        }
    }

    /// Latched by the flip rather than mirroring the orientation, so a covered
    /// balance stays covered once the phone is picked back up. Never persisted:
    /// a launch always starts with the figures showing.
    private(set) var balancesHidden = false

    #if DEBUG
    /// Wins over the real thing, so the masking can be checked on a simulator,
    /// which has no orientation to report.
    var forcesHiddenBalances = false

    /// The latest gravity sample and what the detector made of it, live, for
    /// the debug screen.
    private(set) var flipReadout = "not monitoring"
    #endif

    /// The one question the formatters ask.
    var hidesBalances: Bool {
        #if DEBUG
        if forcesHiddenBalances { return true }
        #endif
        return balancesHidden
    }

    var isMonitoringFlip: Bool { flipDetector.isMonitoring }

    private let flipDetector = FlipDetector()

    init() {
        let defaults = UserDefaults.standard
        selectedCurrency = defaults.string(forKey: Key.currency)
            .flatMap(FiatCurrency.init(rawValue:)) ?? .usd
        showFiat = defaults.object(forKey: Key.showFiat) as? Bool ?? true
        showSatoshi = defaults.object(forKey: Key.showSatoshi) as? Bool ?? false
        flipToHideBalance = defaults.bool(forKey: Key.flipToHide)

        flipDetector.onFlip = { [weak self] in
            self?.balancesHidden.toggle()
        }

        #if DEBUG
        flipDetector.onSample = { [weak self] gravityZ, isFaceDown in
            let z = gravityZ.formatted(.number.precision(.fractionLength(2)).sign(strategy: .always()))
            self?.flipReadout = "z \(z) · \(isFaceDown ? "face down" : "not face down")"
        }
        #endif
    }

    // MARK: - Flip to hide

    /// Driven by the scene phase: nothing reads the accelerometer while the app
    /// is in the background or behind a locked screen.
    func startFlipMonitoring() {
        guard flipToHideBalance else { return }
        flipDetector.start()
    }

    func stopFlipMonitoring() {
        flipDetector.stop()

        #if DEBUG
        flipReadout = "not monitoring"
        #endif
    }

    // MARK: - Formatting

    /// Every figure on screen goes through here, and so does every figure in the
    /// widget. Rebuilt on each read rather than stored: it is five words wide,
    /// and a stored copy is one more thing that can fall out of step with the
    /// settings it mirrors.
    var formatter: BalanceFormatter {
        BalanceFormatter(
            currency: selectedCurrency,
            showSatoshi: showSatoshi,
            showFiat: showFiat,
            price: currentPrice,
            hidesBalances: hidesBalances
        )
    }

    var currentPrice: Double {
        prices[selectedCurrency.apiKey] ?? 0
    }

    /// False when the price fetch failed or hasn't landed yet. Without this check a
    /// failed fetch renders every holding as "$0.00", which reads as "your bitcoin is gone".
    var isFiatAvailable: Bool { formatter.isFiatAvailable }

    var showsFiatValues: Bool { formatter.showsFiatValues }

    func fiatValue(btc: Double) -> Double { formatter.fiatValue(btc: btc) }

    func formattedBTC(_ value: Double) -> String { formatter.formattedBTC(value) }

    /// The bare figure, without a unit. The card draws the unit itself so it can
    /// style it separately.
    func formattedAmount(btc: Double) -> String { formatter.formattedAmount(btc: btc) }

    /// ₿ leads a BTC figure; a sats figure is trailed by its unit instead, since
    /// ₿ denotes whole coins and would be wrong in front of a satoshi count.
    var amountPrefix: String? { formatter.amountPrefix }
    var amountSuffix: String? { formatter.amountSuffix }

    func formattedPending(_ satoshis: Int64) -> String { formatter.formattedPending(satoshis) }

    /// Keeps the cents, for the add-address balance preview where the exact
    /// figure is being confirmed.
    func formattedFiat(_ value: Double) -> String { formatter.formattedFiat(value) }

    /// Whole currency units, used wherever a balance is displayed.
    func formattedFiatWhole(_ value: Double) -> String { formatter.formattedFiatWhole(value) }

    func formattedGoalPercent(_ progress: Double) -> String { formatter.formattedGoalPercent(progress) }

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
        guard !addresses.isEmpty else {
            lastRefreshFailed = false
            return
        }

        let stillFailing = await apply(to: addresses)
        lastRefreshFailed = stillFailing.count == addresses.count

        guard !stillFailing.isEmpty else { return }

        // Deliberately not awaited: `.refreshable` holds its spinner for as long
        // as this call runs, so retrying inline would make every pull-to-refresh
        // feel three seconds slower.
        Task { [weak self] in
            try? await Task.sleep(for: Self.retryDelay)
            await self?.retryQuietly(stillFailing)
        }
    }

    /// Fetches the given addresses and writes the results back, returning those
    /// that still failed.
    @discardableResult
    private func apply(to addresses: [BitcoinAddress]) async -> [BitcoinAddress] {
        let unique = Array(Set(addresses.map(\.address)))
        guard !unique.isEmpty else { return [] }

        let results = await Self.fetchBalances(for: unique)

        var failed: [BitcoinAddress] = []
        for address in addresses {
            switch results[address.address] {
            case .balance(let balance):
                address.apply(balance)
            case .failure(let message):
                address.fetchError = message
                failed.append(address)
            case nil:
                break
            }
        }
        return failed
    }

    /// A single second attempt. On success it clears the error; on failure it
    /// changes nothing, so a failed retry adds no further noise.
    private func retryQuietly(_ addresses: [BitcoinAddress]) async {
        let stillFailing = await apply(to: addresses)
        if stillFailing.isEmpty {
            lastRefreshFailed = false
        }
    }

    private enum BalanceFetch: Sendable {
        case balance(AddressBalance)
        case failure(String)
    }

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
                        let balance = try await BitcoinAPIService.shared.fetchBalance(for: address)
                        return (address, .balance(balance))
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
