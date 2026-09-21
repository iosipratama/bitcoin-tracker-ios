import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(PortfolioViewModel.self) private var viewModel
    @Environment(StoreManager.self) private var store

    @State private var mailUnavailable = false
    @State private var copiedAddress = 0
    @State private var restoreOutcome: String?
    @State private var restoreSucceeded = 0

    private var appVersion: String { "v\(SupportEnvironment.appVersion)" }

    var body: some View {
        @Bindable var bindable = viewModel

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    bitcoinSection(showSatoshi: $bindable.showSatoshi)
                    fiatSection(showFiat: $bindable.showFiat, currency: $bindable.selectedCurrency)
                    appSection(flipToHide: $bindable.flipToHideBalance)
                    supportSection
                    #if DEBUG
                    debugSection
                    #endif
                    rateCard
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(.appBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .tint(.label)
                }
            }
        }
        .fontDesign(.rounded)
        .presentationBackground(.appBackground)
        .alert("No Mail Account", isPresented: $mailUnavailable) {
            Button("Copy Address") {
                UIPasteboard.general.string = SupportLinks.supportAddress
                copiedAddress += 1
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("There's no mail account set up on this device. Copy \(SupportLinks.supportAddress) and write from wherever you like.")
        }
        .alert(
            "Restore Purchase",
            isPresented: Binding { restoreOutcome != nil } set: { presented in
                if !presented { restoreOutcome = nil }
            },
            presenting: restoreOutcome
        ) { _ in
            Button("OK") {}
        } message: { outcome in
            Text(outcome)
        }
        .sensoryFeedback(.success, trigger: copiedAddress)
        .sensoryFeedback(.success, trigger: restoreSucceeded)
    }

    // MARK: - Sections

    private func bitcoinSection(showSatoshi: Binding<Bool>) -> some View {
        SettingsGroup(title: "Bitcoin") {
            SettingsRow(icon: .iconSatoshi, title: "Show in Satoshi") {
                Toggle("Show in Satoshi", isOn: showSatoshi)
                    .labelsHidden()
                    .tint(.brand)
            }
            .onTapGesture { showSatoshi.wrappedValue.toggle() }
        }
    }

    private func fiatSection(showFiat: Binding<Bool>, currency: Binding<FiatCurrency>) -> some View {
        SettingsGroup(title: "Fiat") {
            SettingsRow(
                icon: .iconCircleDollar,
                title: "Show fiat"
            ) {
                Toggle("Show fiat", isOn: showFiat)
                    .labelsHidden()
                    .tint(.brand)
            }
            .onTapGesture { showFiat.wrappedValue.toggle() }

            if viewModel.showFiat {
                // A bare menu-style Picker only reacts to taps on its own value,
                // so the picker lives inside a Menu whose label is the row.
                Menu {
                    Picker("Select currency", selection: currency) {
                        ForEach(FiatCurrency.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } label: {
                    SettingsRow(icon: .iconGlobe, title: "Select currency") {
                        HStack(spacing: 5) {
                            Text(currency.wrappedValue.displayName)
                                .font(.system(size: 17))
                                .foregroundStyle(.label)

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiaryLabel)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select currency")
                .accessibilityValue(currency.wrappedValue.displayName)
                .transition(.opacity)
            }
        }
        .animation(.smooth, value: viewModel.showFiat)
        .onChange(of: currency.wrappedValue) {
            // The cached response carries every currency, so this only matters
            // when the first fetch failed.
            Task { await viewModel.refreshPrices() }
        }
    }

    private func appSection(flipToHide: Binding<Bool>) -> some View {
        SettingsGroup(
            title: "App",
            footer: "Flip your device down to quickly hide and show balances"
        ) {
            SettingsRow(icon: .iconEyeClosed, title: "Flip-to-Hide Balance") {
                Toggle("Flip-to-Hide Balance", isOn: flipToHide)
                    .labelsHidden()
                    .tint(.brand)
            }
            .onTapGesture { flipToHide.wrappedValue.toggle() }
        }
    }

    private var supportSection: some View {
        SettingsGroup(title: "Support") {
            suggestFeatureRow
            ShareLink(item: SupportLinks.appStore) {
                SettingsRow(icon: .iconShareRight, title: "Share with friends") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiaryLabel)
                }
            }
            .buttonStyle(.plain)
            restorePurchaseRow
            SettingsLinkRow(icon: .iconPage, title: "Privacy", url: SupportLinks.privacy)
            SettingsLinkRow(icon: .iconPage, title: "Terms", url: SupportLinks.terms)
            NavigationLink {
                AboutView()
            } label: {
                SettingsRow(icon: .iconInfo, title: "About") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiaryLabel)
                }
            }
            .buttonStyle(.plain)
        }
    }

    #if DEBUG
    private var debugSection: some View {
        SettingsGroup(title: nil) {
            NavigationLink {
                DebugView()
            } label: {
                SettingsRow(systemImage: "ladybug.fill", title: "Debug") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiaryLabel)
                }
            }
            .buttonStyle(.plain)
        }
    }
    #endif

    /// Not a `SettingsLinkRow`: a phone with no mail account set up opens
    /// nothing at all, and a support row that silently does nothing is worse
    /// than one that admits it.
    private var suggestFeatureRow: some View {
        Button {
            openURL(SupportLinks.suggestFeature) { opened in
                mailUnavailable = !opened
            }
        } label: {
            SettingsRow(icon: .iconRaiseHand, title: "Suggest a feature") {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiaryLabel)
            }
        }
        .buttonStyle(.plain)
    }

    /// The only way back to a purchase after a reinstall — the paywall itself
    /// is only reachable by trying to add a wallet past the free limit.
    private var restorePurchaseRow: some View {
        Button {
            Task {
                await store.restore()

                if store.isUnlocked {
                    restoreSucceeded += 1
                    restoreOutcome = "Sato Plus is unlocked on this Apple Account."
                } else {
                    restoreOutcome = store.message ?? "No purchase to restore on this Apple Account."
                }
            }
        } label: {
            SettingsRow(icon: .iconRestore, title: "Restore Purchase") {
                if store.isRestoring {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.secondaryLabel)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiaryLabel)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(store.isRestoring)
    }

    private var rateCard: some View {
        Button {
            openURL(SupportLinks.writeReview)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate Sato")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.label)

                    Text("If this app has been helpful, leave an app store review. It helps a lot.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.yellow)
                        }
                    }
                    .accessibilityHidden(true)
                }

                Spacer(minLength: 0)

                Image(.rateIllustration)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 92)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                    .fill(.groupedBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rate Sato on the App Store")
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.system(size: 13))
                .foregroundStyle(.brand)
                .accessibilityHidden(true)

            Text("Designed by")
                .font(.system(size: 13))
                .foregroundStyle(.secondaryLabel)

            Link(destination: SupportLinks.designer) {
                Text("mekarya")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.label)
            }

            Text("2026 Sato. \(appVersion)")
                .font(.system(size: 12))
                .foregroundStyle(.tertiaryLabel)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

/// The attribution that used to sit inline in Settings.
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Sato is a calm, watch-only bitcoin tracker for long-term holder. It stores no private keys and has no account.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)

                SettingsGroup(title: "Data") {
                    SettingsLinkRow(
                        icon: .iconGlobe,
                        title: "Balances by mempool.space",
                        url: SupportLinks.blockExplorer
                    )
                    SettingsLinkRow(
                        icon: .iconCircleDollar,
                        title: "Prices by CoinGecko",
                        url: SupportLinks.priceData
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(.appBackground)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .fontDesign(.rounded)
    }
}
