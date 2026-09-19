import SwiftUI

/// Decides what a launch opens on. A branch rather than a cover, so `HomeView`
/// doesn't fetch balances behind copy the user is still reading — and so
/// re-arming the flag from Debug tears the settings sheet down with it.
struct RootView: View {
    @AppStorage(AppStorageKey.hasCompletedWelcome) private var hasCompletedWelcome = false

    var body: some View {
        ZStack {
            FigmaPalette.backgroundBase
                .ignoresSafeArea()

            if hasCompletedWelcome {
                HomeView()
                    .transition(.opacity)
            } else {
                WelcomeView {
                    withAnimation(.smooth) { hasCompletedWelcome = true }
                }
                .transition(.opacity.combined(with: .offset(y: -24)))
            }
        }
    }
}

/// Keys shared between the view that owns a value and the debug screen that
/// resets it. `@AppStorage` matches on the raw string, so it can't be a typo.
enum AppStorageKey {
    static let hasCompletedWelcome = "hasCompletedWelcome"

    #if DEBUG
    static let forcesEmptyState = "debugForcesEmptyState"
    #endif
}
