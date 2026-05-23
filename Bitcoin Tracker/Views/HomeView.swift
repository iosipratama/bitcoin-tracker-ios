import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showAddWallet = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if wallets.isEmpty {
                        emptyState
                    } else {
                        ForEach(wallets) { wallet in
                            NavigationLink(value: wallet) {
                                WalletCard(wallet: wallet)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
            .navigationDestination(for: Wallet.self) { wallet in
                WalletDetailView(wallet: wallet)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .refreshable {
                await viewModel.refreshBalances(wallets: wallets)
            }
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.bitcoinOrange)
                            .scaleEffect(0.8)
                    } else {
                        Button { showAddWallet = true } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(Color.bitcoinOrange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddWallet) { AddWalletView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task { await viewModel.refreshBalances(wallets: wallets) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("Your stack begins\nwith one address.")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                showAddWallet = true
            } label: {
                Text("Add Wallet")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.bitcoinOrange)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.bitcoinOrange.opacity(0.4), lineWidth: 1)
                    )
            }
        }
        .padding(.top, 80)
    }
}

// MARK: - Previews

private struct PreviewWallet {
    let name: String
    let satoshis: Int64
    let goalSatoshis: Int64?
}

private let sampleWallets: [PreviewWallet] = [
    PreviewWallet(name: "Stack", satoshis: 21_500_000, goalSatoshis: 100_000_000),
    PreviewWallet(name: "Cold Storage", satoshis: 105_340_200, goalSatoshis: nil),
]

#Preview("With Wallets") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)

    for sample in sampleWallets {
        let wallet = Wallet(name: sample.name)
        let address = BitcoinAddress(address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh")
        address.balanceSatoshis = sample.satoshis
        address.lastUpdated = .now
        wallet.addresses.append(address)
        container.mainContext.insert(wallet)
    }

    return HomeView()
        .modelContainer(container)
        .environment(PortfolioViewModel())
}

#Preview("Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)

    return HomeView()
        .modelContainer(container)
        .environment(PortfolioViewModel())
}
