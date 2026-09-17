import Foundation

enum Quotes {
    /// Picked once per process, so it changes when the app is launched but stays
    /// put while someone is reading it.
    static let current: String = all.randomElement() ?? all[0]

    /// Kept short: the footer is a narrow column and a long line wraps into a
    /// paragraph, which is louder than this screen wants to be.
    static let all: [String] = [
        "Time in the market beats timing the market.",
        "The reward for patience is rarely loud.",
        "You don't have to watch it to own it.",
        "Volatility is the price of admission.",
        "Stack quietly. Check rarely.",
        "Conviction is quieter than confidence.",
        "Not your keys, not your coins.",
        "The best trade is often no trade.",
        "Slow is a strategy, not a failure.",
    ]
}
