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

    /// Asterisks stand in for the digits while balances are hidden. Six for
    /// bitcoin and four for fiat: enough to read as a covered figure without
    /// suggesting how many digits are underneath.
    private static let bitcoinMask = 6
    private static let fiatMask = 4
    private static let goalMask = 2

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
        let figure = showSatoshi
            ? "\(Int64((value * .satoshisPerBTC).rounded()).satsDigits) sats"
            : value.btcDisplay
        return hidesBalances ? masked(figure, digits: Self.bitcoinMask) : figure
    }

    /// The bare figure, without a unit. The card draws the unit itself so it can
    /// style it separately.
    func formattedAmount(btc: Double) -> String {
        guard !hidesBalances else { return String(repeating: "*", count: Self.bitcoinMask) }
        return showSatoshi ? Int64((btc * .satoshisPerBTC).rounded()).satsDigits : btc.btcDigits
    }

    /// ₿ leads a BTC figure; a sats figure is trailed by its unit instead, since
    /// ₿ denotes whole coins and would be wrong in front of a satoshi count.
    var amountPrefix: String? { showSatoshi ? nil : "\u{20BF}" }
    var amountSuffix: String? { showSatoshi ? "sats" : nil }

    /// Signed so an unconfirmed outgoing spend reads as "-0.0010 BTC pending".
    func formattedPending(_ satoshis: Int64) -> String {
        let sign = satoshis < 0 ? "-" : "+"
        let figure = "\(sign)\(abs(Double(satoshis) / .satoshisPerBTC).btcDisplay)"
        return hidesBalances ? masked(figure, digits: Self.bitcoinMask) : figure
    }

    /// Delegates fraction digits to the currency itself — JPY, KRW and VND have
    /// none, so a hardcoded two would have rendered "¥1,234.00". Above four
    /// figures the decimals are dropped entirely; on a rupiah balance they are
    /// only noise.
    func formattedFiat(_ value: Double) -> String {
        let style = FloatingPointFormatStyle<Double>.Currency(code: selectedCurrency.rawValue)
        let figure = abs(value) >= 10_000
            ? value.formatted(style.precision(.fractionLength(0)))
            : value.formatted(style)
        return hidesBalances ? masked(figure, digits: Self.fiatMask) : figure
    }

    /// Whole currency units, used wherever a balance is displayed. Cents are
    /// noise on a glanceable figure, and more so on a rupiah or yen one.
    /// `formattedFiat` keeps them for the add-address balance preview, where the
    /// exact figure is being confirmed.
    func formattedFiatWhole(_ value: Double) -> String {
        let figure = value.formatted(
            FloatingPointFormatStyle<Double>.Currency(code: selectedCurrency.rawValue)
                .precision(.fractionLength(0))
        )
        return hidesBalances ? masked(figure, digits: Self.fiatMask) : figure
    }

    /// Floored rather than rounded: 99.7% of a goal has not reached it. Left
    /// uncapped above 100 so overshoot is visible.
    ///
    /// Masked with the balances because a percentage of a target the owner
    /// chose is the balance restated.
    func formattedGoalPercent(_ progress: Double) -> String {
        guard !hidesBalances else {
            return String(repeating: "*", count: Self.goalMask) + "%"
        }
        let percent = Int((progress * 100).rounded(.down))
        return percent == 0 && progress > 0 ? "<1%" : "\(percent)%"
    }

    /// Replaces the run of digits in an already-formatted figure rather than
    /// building a masked one from scratch, so the currency symbol, the sign and
    /// the unit all survive wherever the locale happens to put them: "$1,234"
    /// masks to "$****" and "1 234 kr" to "**** kr".
    private func masked(_ figure: String, digits: Int) -> String {
        guard let first = figure.firstIndex(where: \.isNumber),
              let last = figure.lastIndex(where: \.isNumber) else { return figure }

        return figure.replacingCharacters(
            in: first...last,
            with: String(repeating: "*", count: digits)
        )
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
