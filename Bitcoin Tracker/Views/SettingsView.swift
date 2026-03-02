import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            List {
                Section("Currency") {
                    ForEach(FiatCurrency.allCases, id: \.self) { currency in
                        Button {
                            viewModel.selectedCurrency = currency
                            Task { await viewModel.refreshPrices() }
                        } label: {
                            HStack {
                                Text("\(currency.symbol) \(currency.rawValue)")
                                    .foregroundStyle(.white)
                                Spacer()
                                if viewModel.selectedCurrency == currency {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.bitcoinOrange)
                                }
                            }
                        }
                    }
                }

                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bitcoin Tracker")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("A minimalist read-only Bitcoin wallet tracker. No private keys are stored or used.")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Link(destination: URL(string: "https://blockstream.info")!) {
                        HStack {
                            Text("Balance data by Blockstream")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    Link(destination: URL(string: "https://www.coingecko.com")!) {
                        HStack {
                            Text("Price data by CoinGecko")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: 0x0A0A0A))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#Preview {
    let viewModel = PortfolioViewModel()
    
    return SettingsView()
        .environment(viewModel)
}

