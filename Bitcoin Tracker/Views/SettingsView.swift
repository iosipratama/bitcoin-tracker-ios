import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioViewModel.self) private var viewModel

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(version)"
    }

    var body: some View {
        @Bindable var bindable = viewModel

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    bitcoinSection(showSatoshi: $bindable.showSatoshi)
                    fiatSection(showFiat: $bindable.showFiat, currency: $bindable.selectedCurrency)
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
    }

    // MARK: - Sections

    private func bitcoinSection(showSatoshi: Binding<Bool>) -> some View {
        SettingsGroup(title: "Bitcoin") {
            SettingsRow(icon: .iconSatoshi, title: "Show in Satoshi") {
                Toggle("", isOn: showSatoshi)
                    .labelsHidden()
                    .tint(.brand)
            }
        }
    }

    private func fiatSection(showFiat: Binding<Bool>, currency: Binding<FiatCurrency>) -> some View {
        SettingsGroup(title: "Fiat") {
            SettingsRow(
                icon: .iconCircleDollar,
                title: "Show fiat"
            ) {
                Toggle("", isOn: showFiat)
                    .labelsHidden()
                    .tint(.brand)
            }

            if viewModel.showFiat {
                SettingsRow(icon: .iconGlobe, title: "Select currency") {
                    Picker("Select currency", selection: currency) {
                        ForEach(FiatCurrency.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(.label)
                }
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

    private var supportSection: some View {
        SettingsGroup(title: "Support") {
            SettingsLinkRow(icon: .iconRaiseHand, title: "Suggest a feature", url: SupportLinks.suggestFeature)
            ShareLink(item: SupportLinks.appStore) {
                SettingsRow(icon: .iconShareRight, title: "Share with friends") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiaryLabel)
                }
            }
            .buttonStyle(.plain)
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
                Label("Debug", systemImage: "ladybug.fill")
                    .labelStyle(DebugRowLabelStyle(showsChevron: true))
            }
            .buttonStyle(.plain)
        }
    }
    #endif

    private var rateCard: some View {
        Button {
            UIApplication.shared.open(SupportLinks.writeReview)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate Sats Keeper")
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
        .accessibilityLabel("Rate Sats Keeper on the App Store")
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

            Text("2026 Sats Keeper. \(appVersion)")
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
                Text("Sats Keeper is a read-only Bitcoin wallet tracker. It stores no private keys and has no account.")
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
