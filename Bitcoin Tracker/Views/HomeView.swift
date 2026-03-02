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
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .background(Color(hex: 0x0A0A0A).ignoresSafeArea())
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
                .foregroundStyle(Color.textSecondary)

            AnimatingNumber(value: viewModel.fiatValue(btc: totalBTC)) { val in
                viewModel.formattedFiat(val)
            }
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(.white)

            AnimatingNumber(value: totalBTC) { val in
                viewModel.formattedBTC(val)
            }
            .font(.subheadline)
            .foregroundStyle(Color.textSecondary)

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.bitcoinOrange)
                    .padding(.top, 4)
                    .accessibilityLabel("Updating balance")
            }

            if let error = viewModel.priceError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.errorText)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private var walletList: some View {
        if wallets.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 16) {
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
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}
#Preview("With Wallets") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)
    
    // Create sample data
    let wallet1 = Wallet(name: "Personal")
    let address1 = BitcoinAddress(address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh")
    address1.balanceSatoshis = 50_000_000 // 0.5 BTC
    address1.lastUpdated = .now
    wallet1.addresses.append(address1)
    
    let wallet2 = Wallet(name: "Savings")
    let address2 = BitcoinAddress(address: "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
    address2.balanceSatoshis = 100_000_000 // 1.0 BTC
    address2.lastUpdated = .now
    wallet2.addresses.append(address2)
    
    container.mainContext.insert(wallet1)
    container.mainContext.insert(wallet2)
    
    let viewModel = PortfolioViewModel()
    
    return HomeView()
        .modelContainer(container)
        .environment(viewModel)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)
    
    let viewModel = PortfolioViewModel()
    
    return HomeView()
        .modelContainer(container)
        .environment(viewModel)
}

