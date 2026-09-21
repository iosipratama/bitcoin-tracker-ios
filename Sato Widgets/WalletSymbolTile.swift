import SwiftUI
import WidgetKit

/// The wallet's accent square, the one piece of a wallet that is recognisably
/// itself at a glance. Same shape the card and the detail header draw, sized to
/// whatever is holding it.
struct WalletSymbolTile: View {
    let symbol: WalletSymbol
    let accent: WalletAccent
    var size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 8 / 25, style: .continuous)
            .fill(accent.color)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol.systemName)
                    .font(.system(size: size * 15 / 25, weight: .semibold))
                    .foregroundStyle(.onAccent)
            }
            // Joins the accent group on a tinted Home Screen, where a
            // per-wallet colour can't survive anyway.
            .widgetAccentable()
            .accessibilityHidden(true)
    }
}

/// Shown when there is no wallet to follow — either Sato has never been opened
/// since the widget was placed, or the chosen wallet has been deleted.
struct WidgetEmptyState: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "bitcoinsign.circle")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Custom.labelQuaternary)

            Text("Open Sato to add a wallet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Custom.labelTertiary)
                .multilineTextAlignment(.center)
        }
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
