import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showAddWallet = false
    @State private var showSettings = false
    @State private var walletToDelete: Wallet? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if wallets.isEmpty {
                        emptyState
                    } else {
                        ForEach(wallets) { wallet in
                            NavigationLink(value: wallet) {
                                WalletRow(wallet: wallet)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    walletToDelete = wallet
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Circle()
                            .fill(Color.bitcoinOrange)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
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
            .navigationDestination(for: Wallet.self) { wallet in
                WalletDetailView(wallet: wallet)
            }
            .refreshable {
                await viewModel.refreshBalances(wallets: wallets)
            }
            .sheet(isPresented: $showAddWallet) { AddWalletView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task { await viewModel.refreshBalances(wallets: wallets) }
            .alert("Remove \(walletToDelete?.name ?? "wallet")?", isPresented: .init(
                get: { walletToDelete != nil },
                set: { if !$0 { walletToDelete = nil } }
            )) {
                Button("Remove", role: .destructive) {
                    if let wallet = walletToDelete {
                        modelContext.delete(wallet)
                    }
                    walletToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    walletToDelete = nil
                }
            } message: {
                Text("This removes the wallet from your tracker. Your bitcoin on-chain is not affected.")
            }
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

#Preview("With Wallets") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)

    let samples: [(String, Int64)] = [
        ("Family saving", 32_221_303),
        ("Anna", 541_234),
        ("Retirement", 1_221_303),
        ("Emergency Fund", 1_212_000),
    ]

    for (name, sats) in samples {
        let wallet = Wallet(name: name)
        let address = BitcoinAddress(address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh")
        address.balanceSatoshis = sats
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
