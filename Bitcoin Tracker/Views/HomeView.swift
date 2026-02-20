import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showAddWallet = false
    @State private var showSettings = false

    private var totalBTC: Double {
        wallets.reduce(0) { $0 + $1.totalBTC }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    portfolioHeader
                    walletList
                }
                .padding()
            }
            .background(Color(hex: 0x0A0A0A))
            .refreshable {
                await viewModel.refreshBalances(wallets: wallets)
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddWallet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.bitcoinOrange)
                    }
                }
            }
            .sheet(isPresented: $showAddWallet) {
                AddWalletView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task {
                await viewModel.refreshBalances(wallets: wallets)
            }
        }
    }

    private var portfolioHeader: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            AnimatingNumber(value: viewModel.fiatValue(btc: totalBTC)) { val in
                viewModel.formattedFiat(val)
            }
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundStyle(.white)

            AnimatingNumber(value: totalBTC) { val in
                viewModel.formattedBTC(val)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.bitcoinOrange)
                    .padding(.top, 4)
            }

            if let error = viewModel.priceError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    private var walletList: some View {
        if wallets.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 12) {
                ForEach(wallets) { wallet in
                    NavigationLink(value: wallet) {
                        WalletCard(wallet: wallet, viewModel: viewModel)
                    }
                }
            }
            .navigationDestination(for: Wallet.self) { wallet in
                WalletDetailView(wallet: wallet)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bitcoinsign.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.bitcoinOrange.opacity(0.5))

            Text("No Wallets Yet")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("Tap + to add your first wallet\nand start tracking your Bitcoin.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}
