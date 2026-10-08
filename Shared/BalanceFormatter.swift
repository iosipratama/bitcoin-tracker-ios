import Foundation

/// Every figure the app puts on screen, in one place.
///
/// Lifted out of `PortfolioViewModel` so the widget can render a balance the
/// same way the app does. The view model is `@MainActor`, `@Observable` and owns
/// a `FlipDetector`, none of which an extension can carry — but the ₿ mark, the
/// ≡ before a fiat figure and the four-decimals-above-one-BTC rule all have to
/// match exactly, or the Home Screen and the app start telling different stories
/// about the same wallet.
nonisolated struct BalanceFormatter: Sendable {

    /// Asterisks stand in for the digits while balances are hidden.
    private static let bitcoinMask = 6
    private static let fiatMask = 4

    var currency: FiatCurrency
    var showSatoshi: Bool
    var showFiat: Bool

    /// One BTC in `currency`. Zero when the price fetch failed or hasn't landed.
    var price: Double = 0

    /// Set by flip-to-hide. A widget never sets it — the Home Screen has no
    /// gesture to turn face down.
    var hidesBalances: Bool = false

    /// False when the price fetch failed or hasn't landed yet.
    var isFiatAvailable: Bool { price > 0 }

    var showsFiatValues: Bool { showFiat && isFiatAvailable }

    func fiatValue(btc: Double) -> Double { btc * price }

    func formattedBTC(_ value: Double) -> String {
        let figure = showSatoshi
            ? "\(Int64((value * .satoshisPerBTC).rounded()).satsDigits) sats"
            : value.btcDisplay
        return hidesBalances ? masked(figure, digits: Self.bitcoinMask) : figure
    }

    /// The bare figure, without a unit.
    func formattedAmount(btc: Double) -> String {
        guard !hidesBalances else { return String(repeating: "*", count: Self.bitcoinMask) }
        return showSatoshi ? Int64((btc * .satoshisPerBTC).rounded()).satsDigits : btc.btcDigits
    }

    /// Like `formattedAmount(btc:)`, but without the trailing zeros a round
    /// target would otherwise carry.
    func formattedGoalAmount(btc: Double) -> String {
        guard !hidesBalances, !showSatoshi else { return formattedAmount(btc: btc) }
        return btc.trimmedBTCDigits
    }

    func formattedGoalBTC(_ value: Double) -> String {
        guard !hidesBalances, !showSatoshi else { return formattedBTC(value) }
        return "\(value.trimmedBTCDigits) BTC"
    }

    /// ₿ leads a BTC figure; a sats figure is trailed by its unit instead.
    var amountPrefix: String? { showSatoshi ? nil : "\u{20BF}" }
    var amountSuffix: String? { showSatoshi ? "sats" : nil }

    /// Signed so an unconfirmed outgoing spend reads as "-0.0010 BTC pending".
    func formattedPending(_ satoshis: Int64) -> String {
        let sign = satoshis < 0 ? "-" : "+"
        let figure = "\(sign)\(abs(Double(satoshis) / .satoshisPerBTC).btcDisplay)"
        return hidesBalances ? masked(figure, digits: Self.bitcoinMask) : figure
    }

    /// Delegates fraction digits to the currency itself. Above four figures the
    /// decimals are dropped entirely.
    func formattedFiat(_ value: Double) -> String {
        let style = FloatingPointFormatStyle<Double>.Currency(code: currency.rawValue)
        let figure = abs(value) >= 10_000
            ? value.formatted(style.precision(.fractionLength(0)))
            : value.formatted(style)
        return hidesBalances ? masked(figure, digits: Self.fiatMask) : figure
    }

    /// Whole currency units, used wherever a balance is displayed.
    func formattedFiatWhole(_ value: Double) -> String {
        let figure = value.formatted(
            FloatingPointFormatStyle<Double>.Currency(code: currency.rawValue)
                .precision(.fractionLength(0))
        )
        return hidesBalances ? masked(figure, digits: Self.fiatMask) : figure
    }

    /// Floored rather than rounded. Deliberately outside the flip-to-hide mask.
    func formattedGoalPercent(_ progress: Double) -> String {
        let percent = Int((progress * 100).rounded(.down))
        return percent == 0 && progress > 0 ? "<1%" : "\(percent)%"
    }

    /// Replaces the run of digits in an already-formatted figure: "$1,234"
    /// masks to "$****" and "1 234 kr" to "**** kr".
    private func masked(_ figure: String, digits: Int) -> String {
        guard let first = figure.firstIndex(where: \.isNumber),
              let last = figure.lastIndex(where: \.isNumber) else { return figure }

        return figure.replacingCharacters(
            in: first...last,
            with: String(repeating: "*", count: digits)
        )
    }
}
