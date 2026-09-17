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
/// side. The glyph is a template asset, so it tints from the colour roles
/// rather than carrying its own colour.
struct SettingsRow<Trailing: View>: View {
    let icon: ImageResource
    let title: String
    var showsDivider: Bool = true
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.secondaryLabel)
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
                    .padding(.leading, 52)
            }
        }
    }
}

/// A row that opens a URL, with the chevron the design shows.
struct SettingsLinkRow: View {
    let icon: ImageResource
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
