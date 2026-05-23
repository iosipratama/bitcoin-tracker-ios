import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    currencySection
                    aboutSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.bitcoinOrange)
                }
            }
        }
        .presentationBackground(Color.appBackground)
    }

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Fiat Currency")

            Rectangle()
                .fill(Color.rowDivider)
                .frame(height: 0.5)

            ForEach(FiatCurrency.allCases, id: \.self) { currency in
                Button {
                    viewModel.selectedCurrency = currency
                    Task { await viewModel.refreshPrices() }
                } label: {
                    HStack {
                        Text("\(currency.symbol) \(currency.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        if viewModel.selectedCurrency == currency {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.bitcoinOrange)
                        }
                    }
                    .padding(.vertical, 14)
                }

                if currency != FiatCurrency.allCases.last {
                    Rectangle()
                        .fill(Color.rowDivider)
                        .frame(height: 0.5)
                }
            }

            Rectangle()
                .fill(Color.rowDivider)
                .frame(height: 0.5)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("About")

            Rectangle()
                .fill(Color.rowDivider)
                .frame(height: 0.5)

            VStack(alignment: .leading, spacing: 6) {
                Text("Bitcoin Tracker")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text("A minimalist read-only wallet tracker.\nNo private keys stored or used.")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(3)
            }
            .padding(.vertical, 14)

            Rectangle()
                .fill(Color.rowDivider)
                .frame(height: 0.5)

            Link(destination: URL(string: "https://blockstream.info")!) {
                HStack {
                    Text("Balance data by Blockstream")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                }
                .padding(.vertical, 14)
            }

            Rectangle()
                .fill(Color.rowDivider)
                .frame(height: 0.5)

            Link(destination: URL(string: "https://www.coingecko.com")!) {
                HStack {
                    Text("Price data by CoinGecko")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                }
                .padding(.vertical, 14)
            }

            Rectangle()
                .fill(Color.rowDivider)
                .frame(height: 0.5)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(Color.textSecondary)
            .kerning(1.5)
            .textCase(.uppercase)
    }
}

#Preview {
    let viewModel = PortfolioViewModel()

    return SettingsView()
        .environment(viewModel)
}
