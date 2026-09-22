import SwiftUI
import UIKit

// MARK: - Palette

/// Raw values, and the only place they appear. Everything below names a role
/// instead, so call sites say what a colour is *for* rather than what it looks
/// like — the same split the system makes between `label` and `white`.
///
/// Every value carries a light and a dark reading. The dark palette came first
/// and sets the structure: the page is the deepest surface, a card lifts off
/// it, and the panel nested inside a card drops back to the page tone. Light
/// keeps that structure and inverts the direction — paper for the page, white
/// for the cards, paper again for the inset — so the two themes are the same
/// design under different light rather than two designs.
private enum Palette {
    /// Warm off-white rather than pure white or the system's cool grey. White
    /// cards need something to lift off, and a hint of warmth matches the dark
    /// palette's own bias.
    static let paper: UInt = 0xF4F3F0
    static let ink: UInt = 0x1A1A18

    static let brandDisabled = Color(light: 0xF3D2A8, dark: 0x7A4A0D)
    static let negative = Color(light: 0xD9453D, dark: 0xFF6B6B)

    /// Prose colours. `bitcoinWord` pulls away from `brand` in whichever
    /// direction legibility lies — brighter on dark, deeper on light — because
    /// it sits inside a sentence rather than on a card. The arrows are the
    /// system's own green and red.
    static let bitcoinWord = Color(light: 0xDB7A0B, dark: 0xFF8D28)
    static let rising = Color(light: 0x2EAF4F, dark: 0x34C759)
    static let falling = Color(light: 0xE5322B, dark: 0xFF383C)

    static let background = Color(light: paper, dark: 0x141414)
    static let cardBackground = Color(light: 0xEBEAE6, dark: 0x262626)
    static let cardInsetBackground = Color(light: paper, dark: 0x141414)
    static let groupedBackground = Color(light: 0xFFFFFF, dark: 0x1F1F1F)
    static let controlFill = Color(light: 0xFFFFFF, dark: 0x242218, opacity: 0.8)
    static let divider = Color(light: 0x000000, dark: 0xFFFFFF, opacity: 0.08)

    /// The unfilled part of a progress indicator. Opaque rather than a wash:
    /// it has to hold the same value on every card surface it sits on.
    static let progressTrack = Color(light: 0xE7E6E2, dark: 0x343434)

    /// Sits on a saturated accent tile, so it takes its cue from the tile and
    /// not the page — near-black in both themes, because the tile doesn't
    /// change either.
    static let onAccent = Color(hex: 0x10100E)
}

// MARK: - Design variables

/// The design file's own variables, named to match it rather than to match the
/// tool that draws it: `custom-label-quaternary` there is `Custom.labelQuaternary`
/// here, so a value can be checked against Dev Mode without translating first.
/// `accent` and `black` carry no prefix in the file and keep their bare names.
///
/// Views read these directly. `Palette` above still backs the semantic roles,
/// which are moving across one at a time.
///
/// The label tiers are alpha over ink rather than opaque greys, which is how
/// the system's own label colours work: a translucent tier composites correctly
/// over any surface. Light alphas run a little heavier than dark ones at each
/// tier, because dark text on a light page loses legibility faster than the
/// reverse at the same nominal contrast.
enum Custom {
    static let backgroundBase = Color(light: Palette.paper, dark: 0x141414)

    static let labelPrimary = Color(light: Palette.ink, dark: 0xFFFFFF)
    static let labelSecondary = Color(
        light: Color(hex: Palette.ink, opacity: 0.74),
        dark: Color(hex: 0xFFFFFF, opacity: 0.80)
    )
    static let labelTertiary = Color(
        light: Color(hex: Palette.ink, opacity: 0.46),
        dark: Color(hex: 0xFFFFFF, opacity: 0.40)
    )
    static let labelQuaternary = Color(
        light: Color(hex: Palette.ink, opacity: 0.24),
        dark: Color(hex: 0xFFFFFF, opacity: 0.20)
    )

    /// The one colour that never changes with the theme. It is the app icon,
    /// the toggles and the word on the tin, and it reads as Bitcoin on paper
    /// exactly as it does on black.
    static let accent = Color(hex: 0xF7931A)
    static let black = Color(hex: 0x000000)

    static let fillPrimary = Color(light: 0xFFFFFF, dark: 0x1F1F1F)
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

    // Label tiers. Same construction as the `Custom` tiers above; these are
    // the roles that predate the design file and sit a step quieter.

    /// Primary text: balances, wallet names in detail, field input.
    static var label: Color { Custom.labelPrimary }

    /// Supporting text: captions, units, section headers.
    static var secondaryLabel: Color {
        Color(
            light: Color(hex: Palette.ink, opacity: 0.56),
            dark: Color(hex: 0xFFFFFF, opacity: 0.48)
        )
    }

    /// De-emphasised detail: timestamps, hints, attribution.
    static var tertiaryLabel: Color {
        Color(
            light: Color(hex: Palette.ink, opacity: 0.36),
            dark: Color(hex: 0xFFFFFF, opacity: 0.30)
        )
    }

    // Accent.

    /// Interactive affordances, pending amounts, the app's tint. Resolves to
    /// the Figma accent, so the token and the role can't drift apart.
    static var brand: Color { Custom.accent }

    /// The accent at rest — confirmation actions that aren't yet available.
    static var brandDisabled: Color { Palette.brandDisabled }

    /// Errors, and amounts moving the wrong way.
    static var negative: Color { Palette.negative }

    /// The word "bitcoin" wherever it appears in running copy.
    static var bitcoinWord: Color { Palette.bitcoinWord }

    /// Direction in prose — price moving up, and down. Distinct from
    /// `negative`, which means something failed.
    static var rising: Color { Palette.rising }
    static var falling: Color { Palette.falling }

    // Surfaces, ordered by elevation.

    /// The page behind everything.
    static var appBackground: Color { Palette.background }

    /// A wallet card.
    static var cardBackground: Color { Palette.cardBackground }

    /// The balance panel nested inside a card, one step further in.
    static var cardInsetBackground: Color { Palette.cardInsetBackground }

    /// Grouped rows — settings sections and the rate card. Sits lower than a
    /// wallet card, which competes with the page for attention by design.
    static var groupedBackground: Color { Palette.groupedBackground }

    /// Foreground for glyphs drawn on an accent tile.
    static var onAccent: Color { Palette.onAccent }

    /// Control interiors — text fields and inputs.
    static var controlFill: Color { Palette.controlFill }

    /// Hairline rule between rows.
    static var divider: Color { Palette.divider }
    static var progressTrack: Color { Palette.progressTrack }

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

    /// One colour with a reading for each appearance. SwiftUI has no way to
    /// declare this in code — only in an asset catalog — so the pair goes
    /// through UIKit's dynamic provider, which re-resolves whenever the colour
    /// scheme around the view changes. That includes the app's own theme
    /// override, not just the system setting.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    /// The common case: two hex values sharing one opacity.
    init(light: UInt, dark: UInt, opacity: Double = 1.0) {
        self.init(
            light: Color(hex: light, opacity: opacity),
            dark: Color(hex: dark, opacity: opacity)
        )
    }
}

extension CGFloat {
    /// Close and confirm in a sheet's top bar. 44 is the minimum comfortable
    /// tap target, and keeping both on one constant keeps them balanced.
    static let sheetButton: CGFloat = 44

    static let cardRadius: CGFloat = 18
    static let rowRadius: CGFloat = 12

    /// The balance panel nested inside a card — a touch tighter than the card
    /// that holds it, so the two curves don't read as one.
    static let cardInsetRadius: CGFloat = 16
}
