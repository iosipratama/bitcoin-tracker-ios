import Foundation

struct Quote: Identifiable, Hashable {
    let text: String
    let attribution: String?

    var id: String { text }
}

enum Quotes {
    /// Picked once per process, so it changes when the app is launched but stays
    /// put while someone is reading it.
    static let current: Quote = all.randomElement() ?? all[0]

    static let all: [Quote] = [
        Quote(
            text: "It might make sense just to get some in case it catches on.",
            attribution: "Satoshi Nakamoto"
        ),
        Quote(
            text: "The root problem with conventional currency is all the trust that's required to make it work.",
            attribution: "Satoshi Nakamoto"
        ),
        Quote(
            text: "If you don't believe it or don't get it, I don't have the time to try to convince you.",
            attribution: "Satoshi Nakamoto"
        ),
        Quote(
            text: "Time in the market beats timing the market.",
            attribution: nil
        ),
        Quote(
            text: "The reward for patience is rarely loud.",
            attribution: nil
        ),
        Quote(
            text: "You don't have to watch it to own it.",
            attribution: nil
        ),
        Quote(
            text: "Volatility is the price of admission, not a reason to leave.",
            attribution: nil
        ),
    ]
}
