import SwiftUI

/// A titled group of settings rows on a single rounded surface. Rows are
/// separated by spacing alone — no hairlines. An optional footer explains the
/// group below the surface, the way the system's own grouped lists do.
struct SettingsGroup<Content: View>: View {
    let title: String?
    var footer: String?
    @ViewBuilder var content: Content

    var body: some View {
        // Two stacks rather than one: the footer sits 12 below the surface,
        // which a shared spacing of 8 would turn into 20.
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if let title {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondaryLabel)
                        .padding(.horizontal, 4)
                }

                VStack(spacing: 0) {
                    content
                }
                .background(
                    RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                        .fill(.groupedBackground)
                )
            }

            if let footer {
                Text(footer)
                    .font(.system(size: 15))
                    .foregroundStyle(Custom.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
                    .padding(.top, 12)
            }
        }
    }
}

/// One row: leading glyph, label, and whatever the row is for on the trailing
/// side. The glyph is a template asset, so it tints from the colour roles
/// rather than carrying its own colour.
struct SettingsRow<Trailing: View>: View {
    private enum Glyph {
        case asset(ImageResource)
        case symbol(String)
    }

    private let glyph: Glyph
    private let title: String
    private let trailing: Trailing

    init(icon: ImageResource, title: String, @ViewBuilder trailing: () -> Trailing) {
        self.glyph = .asset(icon)
        self.title = title
        self.trailing = trailing()
    }

    /// For rows with no drawn asset of their own — the debug screen, which
    /// isn't worth commissioning artwork for.
    init(systemImage: String, title: String, @ViewBuilder trailing: () -> Trailing) {
        self.glyph = .symbol(systemImage)
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 14) {
            glyphView
                .frame(width: 22, height: 22)
                .foregroundStyle(.secondaryLabel)
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.label)

            Spacer(minLength: 8)

            trailing
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        // Without this the gap between the label and the trailing control isn't
        // hit-testable, so rows wrapped in a button only respond to their text.
        .contentShape(.rect)
    }

    @ViewBuilder private var glyphView: some View {
        switch glyph {
        case .asset(let resource):
            Image(resource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: 17))
        }
    }
}

/// A row that opens a URL, with the chevron the design shows.
struct SettingsLinkRow: View {
    let icon: ImageResource
    let title: String
    let url: URL

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            SettingsRow(icon: icon, title: title) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiaryLabel)
            }
        }
        .buttonStyle(.plain)
    }
}
