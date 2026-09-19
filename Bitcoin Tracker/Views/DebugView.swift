#if DEBUG
import SwiftUI

/// A private testing surface, compiled out of release builds. Actions here
/// re-arm state the app is otherwise meant to reach only once.
struct DebugView: View {
    @AppStorage(AppStorageKey.hasCompletedWelcome) private var hasCompletedWelcome = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SettingsGroup(title: "First launch") {
                    Button("Show welcome screen", systemImage: "hand.wave") {
                        withAnimation(.smooth) { hasCompletedWelcome = false }
                    }
                    .buttonStyle(.plain)
                    .labelStyle(DebugRowLabelStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(.appBackground)
        .navigationTitle("Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Renders a label as a settings row. `SettingsRow` takes a drawn asset for its
/// glyph and there is no debug asset, so this is the SF Symbol equivalent —
/// debug-only, which is why it doesn't live alongside `SettingsRow`.
struct DebugRowLabelStyle: LabelStyle {
    var showsChevron = false

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 14) {
            configuration.icon
                .font(.system(size: 17))
                .frame(width: 22, height: 22)
                .foregroundStyle(.secondaryLabel)

            configuration.title
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.label)

            Spacer(minLength: 8)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiaryLabel)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .contentShape(.rect)
    }
}
#endif
