import SwiftUI

extension Font {
    /// The headline balance on a wallet's own screen. Same size the Georgia
    /// serif occupied, now in the rounded face the rest of the app uses.
    static let walletTotal = Font.system(size: 32, weight: .bold)
}

extension Font {
    // Wallet card. `.fontDesign(.rounded)` is applied once on the card root and
    // cascades, so these deliberately don't carry a design of their own.
    static let walletName = Font.system(size: 16, weight: .semibold)
    static let walletBalance = Font.system(size: 17, weight: .bold)

    /// The ₿ ahead of the balance. Heavier than the figure it introduces, so it
    /// reads as a mark rather than a leading digit.
    static let walletBalanceMark = Font.system(size: 17, weight: .heavy)
    static let walletFiat = Font.system(size: 15, weight: .semibold)
}
