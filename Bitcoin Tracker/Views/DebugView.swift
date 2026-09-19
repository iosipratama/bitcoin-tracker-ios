#if DEBUG
import SwiftUI

/// A private testing surface, compiled out of release builds. Everything here
/// re-arms or overrides state the app is otherwise meant to reach only by
/// using it normally.
struct DebugView: View {
    @AppStorage(AppStorageKey.hasCompletedWelcome) private var hasCompletedWelcome = false
    @AppStorage(AppStorageKey.forcesEmptyState) private var forcesEmptyState = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SettingsGroup(title: "Main view") {
                    SettingsRow(systemImage: "tray", title: "Force empty state") {
                        Toggle("Force empty state", isOn: $forcesEmptyState)
                            .labelsHidden()
                            .tint(.brand)
                    }
                }

                SettingsGroup(title: "First launch") {
                    Button {
                        withAnimation(.smooth) { hasCompletedWelcome = false }
                    } label: {
                        SettingsRow(systemImage: "hand.wave", title: "Show welcome screen") {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)
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
#endif
