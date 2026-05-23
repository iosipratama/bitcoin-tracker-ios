import SwiftUI

extension Color {
    static let bitcoinOrange = Color(hex: 0xD4823B)
    static let bitcoinOrangeDisabled = Color(hex: 0x7A4A0D)

    // WCAG AA compliant on true black (#000000)
    static let textSecondary = Color(hex: 0x888888)
    static let errorText = Color(hex: 0xFF6B6B)

    // Page background — warm dark gray
    static let appBackground = Color(hex: 0x1A1A1A)

    // Card surface — visible lift off background, no border needed
    static let cardBackground = Color(hex: 0x272727)

    // Warm surface for form inputs
    static let surfaceWarm = Color(hex: 0x242218, opacity: 0.8)

    // Hairline divider
    static let rowDivider = Color(hex: 0xFFFFFF, opacity: 0.08)

    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension CGFloat {
    static let cardRadius: CGFloat = 16
    static let rowRadius: CGFloat = 12
}

