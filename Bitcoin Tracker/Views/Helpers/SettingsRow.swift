import SwiftUI

/// A grouped card of settings rows, drawn on the card surface with hairlines
/// between rows rather than around the group.
struct SettingsGroup<Content: View>: View {
    let title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondaryLabel)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                    .fill(.cardBackground)
            )
        }
    }
}

/// One row: leading glyph, label, and whatever the row is for on the trailing
/// side. The glyph is a placeholder SF Symbol until the custom artwork lands —
/// swapping it means changing `icon` to an `Image(.assetName)`.
struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    var showsDivider: Bool = true
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.secondaryLabel)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.label)

                Spacer(minLength: 8)

                trailing
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)

            if showsDivider {
                Rectangle()
                    .fill(.divider)
                    .frame(height: 0.5)
                    .padding(.leading, 54)
            }
        }
    }
}

/// A row that opens a URL, with the chevron the design shows.
struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let url: URL
    var showsDivider: Bool = true

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            SettingsRow(icon: icon, title: title, showsDivider: showsDivider) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiaryLabel)
            }
        }
        .buttonStyle(.plain)
    }
}
