import SwiftUI

extension Font {
    // Georgia serif — used exclusively for balance figures
    static let balanceLarge = Font.custom("Georgia", size: 44)
    static let balanceMedium = Font.custom("Georgia", size: 32)
}

extension Font {
    // Wallet card. `.fontDesign(.rounded)` is applied once on the card root and
    // cascades, so these deliberately don't carry a design of their own.
    static let walletName = Font.system(size: 16, weight: .semibold)
    static let walletBalance = Font.system(size: 17, weight: .bold)
    static let walletFiat = Font.system(size: 15, weight: .semibold)
}
