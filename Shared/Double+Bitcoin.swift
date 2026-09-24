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

    /// A goal is a figure someone chose, usually a round one, so it keeps full
    /// satoshi precision but drops the trailing zeros: 5, 0.1, 0.25.
    var trimmedBTCDigits: String {
        var text = String(format: "%.8f", self)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }
}

nonisolated extension Int64 {
    /// Grouped by the reader's locale, so a sats figure stays scannable.
    var satsDigits: String { formatted(.number) }
}
