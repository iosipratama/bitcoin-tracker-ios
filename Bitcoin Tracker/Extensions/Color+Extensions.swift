import SwiftUI

// MARK: - Palette

/// Raw values, and the only place they appear. Everything below names a role
/// instead, so call sites say what a colour is *for* rather than what it looks
/// like — the same split the system makes between `label` and `white`.
private enum Palette {
    static let brand = Color(hex: 0xD4823B)
    static let brandDisabled = Color(hex: 0x7A4A0D)
    static let negative = Color(hex: 0xFF6B6B)

    static let background = Color(hex: 0x1A1A1A)
    static let elevatedBackground = Color(hex: 0x272727)
    static let controlFill = Color(hex: 0x242218, opacity: 0.8)
    static let divider = Color(hex: 0xFFFFFF, opacity: 0.08)
}

// MARK: - Semantic roles

/// Declared on `ShapeStyle` rather than `Color` so they read with a leading dot
/// at the call site — `.foregroundStyle(.secondaryLabel)` — which is the same
/// mechanism behind `.foregroundStyle(.red)`. `Color.secondaryLabel` still
/// resolves for the places that need a concrete `Color`, such as ternaries and
/// gradient stops.
///
/// Deliberately avoids the names `secondary` and `tertiary`: SwiftUI already
/// defines those as `HierarchicalShapeStyle`, and shadowing them would break
/// `.foregroundStyle(.secondary)` everywhere.
extension ShapeStyle where Self == Color {

    // Label tiers.
    //
    // Alpha over white rather than opaque greys, which is how the system's own
    // label colours work. A translucent tier composites correctly over any
    // surface, so one value serves the page, a form field and a sheet without
    // per-surface correction. The alphas reproduce the previous opaque greys
    // over the app background.

    /// Primary text: balances, wallet names in detail, field input.
    static var label: Color { .white }

    /// Supporting text: captions, units, section headers.
    static var secondaryLabel: Color { .white.opacity(0.48) }

    /// De-emphasised detail: timestamps, hints, attribution.
    static var tertiaryLabel: Color { .white.opacity(0.30) }

    // Accent.

    /// Interactive affordances, pending amounts, the app's tint.
    static var brand: Color { Palette.brand }

    /// The accent at rest — confirmation actions that aren't yet available.
    static var brandDisabled: Color { Palette.brandDisabled }

    /// Errors, and amounts moving the wrong way.
    static var negative: Color { Palette.negative }

    // Surfaces, ordered by elevation.

    /// The page behind everything.
    static var appBackground: Color { Palette.background }

    /// One step up: cards and grouped surfaces.
    static var elevatedBackground: Color { Palette.elevatedBackground }

    /// Control interiors — text fields and inputs.
    static var controlFill: Color { Palette.controlFill }

    /// Hairline rule between rows.
    static var divider: Color { Palette.divider }
}

extension Color {
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
