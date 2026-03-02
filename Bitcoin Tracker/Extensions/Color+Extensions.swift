import SwiftUI

extension Color {
    // Muted copper tone - editorial, restrained alternative to bright Bitcoin orange
    static let bitcoinOrange = Color(hex: 0xD4823B)
    
    // Disabled state for orange accent
    static let bitcoinOrangeDisabled = Color(hex: 0x7A4A0D)
    
    // WCAG AA compliant secondary text (5.7:1 contrast on #0A0A0A)
    static let textSecondary = Color(hex: 0xA0A0A0)
    
    // WCAG AA compliant error text (5.1:1 contrast on #0A0A0A)
    static let errorText = Color(hex: 0xFF6B6B)

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

