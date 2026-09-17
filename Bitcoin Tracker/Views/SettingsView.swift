import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioViewModel.self) private var viewModel

    var body: some View {
        @Bindable var bindable = viewModel

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    fiatSection(showFiat: $bindable.showFiat, currency: $bindable.selectedCurrency)
                    aboutSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .background(.appBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.brand)
                }
            }
        }
        .presentationBackground(.appBackground)
    }

    private func fiatSection(showFiat: Binding<Bool>, currency: Binding<FiatCurrency>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Fiat Value")

            Rectangle()
                .fill(.divider)
                .frame(height: 0.5)

            Toggle(isOn: showFiat) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show fiat value")
                        .font(.subheadline)
                        .foregroundStyle(.label)
                    Text("Off keeps every figure denominated in bitcoin.")
                        .font(.caption)
                        .foregroundStyle(.secondaryLabel)
                }
            }
            .tint(.brand)
            .padding(.vertical, 14)

            Rectangle()
                .fill(.divider)
                .frame(height: 0.5)

            if viewModel.showFiat {
                currencyPicker(currency: currency)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.smooth, value: viewModel.showFiat)
    }

    private func currencyPicker(currency: Binding<FiatCurrency>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Currency")
                    .font(.subheadline)
                    .foregroundStyle(.label)

                Spacer()

                Picker("Currency", selection: currency) {
                    ForEach(FiatCurrency.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(.brand)
            }
            .padding(.vertical, 6)

            Rectangle()
                .fill(.divider)
                .frame(height: 0.5)
                .padding(.top, 8)
        }
        .onChange(of: currency.wrappedValue) {
            // The cached response carries every currency, so this only matters
            // when the first fetch failed.
            Task { await viewModel.refreshPrices() }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("About")

            Rectangle()
                .fill(.divider)
                .frame(height: 0.5)

            VStack(alignment: .leading, spacing: 6) {
                Text("Bitcoin Tracker")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.label)
                Text("A minimalist read-only wallet tracker.\nNo private keys stored or used.")
                    .font(.caption)
                    .foregroundStyle(.secondaryLabel)
                    .lineSpacing(3)
            }
            .padding(.vertical, 14)

            Rectangle()
                .fill(.divider)
                .frame(height: 0.5)

            Link(destination: URL(string: "https://mempool.space")!) {
                HStack {
                    Text("Balance data by mempool.space")
                        .font(.subheadline)
                        .foregroundStyle(.secondaryLabel)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiaryLabel)
                }
                .padding(.vertical, 14)
            }

            Rectangle()
                .fill(.divider)
                .frame(height: 0.5)

            Link(destination: URL(string: "https://www.coingecko.com")!) {
                HStack {
                    Text("Price data by CoinGecko")
                        .font(.subheadline)
                        .foregroundStyle(.secondaryLabel)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiaryLabel)
                }
                .padding(.vertical, 14)
            }

            Rectangle()
                .fill(.divider)
                .frame(height: 0.5)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondaryLabel)
            .kerning(1.5)
            .textCase(.uppercase)
    }
}

#Preview {
    let viewModel = PortfolioViewModel()

    return SettingsView()
        .environment(viewModel)
}
