import Foundation

nonisolated extension Double {
    /// Four decimals above 1 BTC, full satoshi precision below — enough detail to
    /// track a stack without turning every figure into eight digits of noise.
    var btcDigits: String {
        if self == 0 { return "0.00000000" }
        if self >= 1 { return String(format: "%.4f", self) }
        return String(format: "%.8f", self)
    }

    var btcDisplay: String { "\(btcDigits) BTC" }
}

nonisolated extension Int64 {
    /// Grouped by the reader's locale, so a sats figure stays scannable.
    var satsDigits: String { formatted(.number) }
}
