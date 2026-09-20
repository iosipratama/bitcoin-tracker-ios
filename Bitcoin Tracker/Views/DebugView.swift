#if DEBUG
import SwiftUI

/// A private testing surface, compiled out of release builds. Everything here
/// re-arms or overrides state the app is otherwise meant to reach only by
/// using it normally.
struct DebugView: View {
    @AppStorage(AppStorageKey.hasCompletedWelcome) private var hasCompletedWelcome = false
    @AppStorage(AppStorageKey.forcesEmptyState) private var forcesEmptyState = false
    @Environment(StoreManager.self) private var store
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showPaywall = false

    var body: some View {
        @Bindable var store = store
        @Bindable var viewModel = viewModel

        return ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SettingsGroup(
                    title: "Flip to hide",
                    footer: "The simulator has no accelerometer, so the override is the only way to see the masking there."
                ) {
                    SettingsRow(systemImage: "eye.slash", title: "Force hidden balances") {
                        Toggle("Force hidden balances", isOn: $viewModel.forcesHiddenBalances)
                            .labelsHidden()
                            .tint(.brand)
                    }

                    SettingsRow(systemImage: "iphone.gen3", title: "Gravity") {
                        Text(viewModel.flipReadout)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondaryLabel)
                    }

                    SettingsRow(systemImage: "dot.radiowaves.left.and.right", title: "Monitoring") {
                        Text(viewModel.isMonitoringFlip ? "yes" : "no")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondaryLabel)
                    }
                }

                SettingsGroup(title: "Main view") {
                    SettingsRow(systemImage: "tray", title: "Force empty state") {
                        Toggle("Force empty state", isOn: $forcesEmptyState)
                            .labelsHidden()
                            .tint(.brand)
                    }
                }

                SettingsGroup(title: "Purchases") {
                    Button {
                        showPaywall = true
                    } label: {
                        SettingsRow(systemImage: "creditcard", title: "Show paywall") {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)

                    SettingsRow(systemImage: "lock.open", title: "Fake unlock") {
                        Toggle("Fake unlock", isOn: $store.fakesUnlock)
                            .labelsHidden()
                            .tint(.brand)
                    }

                    SettingsRow(systemImage: "plus.circle", title: "Always show paywall") {
                        Toggle("Always show paywall", isOn: $store.forcesPaywall)
                            .labelsHidden()
                            .tint(.brand)
                    }
                }

                SettingsGroup(title: "One-time prompts") {
                    Button {
                        withAnimation(.smooth) { hasCompletedWelcome = false }
                    } label: {
                        SettingsRow(systemImage: "hand.wave", title: "Show welcome screen") {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        ReviewPrompt.reset()
                    } label: {
                        SettingsRow(systemImage: "star", title: "Re-arm review prompt") {
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
        .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
    }
}
#endif
