import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showAddWallet = false
    @State private var showSettings = false
    @State private var walletToDelete: Wallet? = nil
    @State private var selectedWallet: Wallet? = nil

    /// The oldest successful fetch across the portfolio — the honest answer to
    /// "how current is this number?"
    private var oldestUpdate: Date? {
        wallets.flatMap(\.addresses).compactMap(\.lastUpdated).min()
    }

    var body: some View {
        NavigationStack {
            Group {
                if wallets.isEmpty {
                    emptyState
                } else {
                    walletList
                }
            }
            .safeAreaInset(edge: .bottom) { quoteFooter }
            .background(.appBackground)
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                        .tint(.brand)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.brand)
                            .scaleEffect(0.8)
                            .accessibilityLabel("Refreshing balances")
                    } else {
                        Button("Add Wallet", systemImage: "plus") { showAddWallet = true }
                            .tint(.brand)
                    }
                }
            }
            .navigationDestination(item: $selectedWallet) { wallet in
                WalletDetailView(wallet: wallet)
            }
            .sheet(isPresented: $showAddWallet) { AddWalletFlow() }
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

    // Swipe actions only exist on List rows — in a LazyVStack the modifier is silently ignored.
    private var walletList: some View {
        List {
            if viewModel.lastRefreshFailed {
                statusLine
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 4, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            ForEach(wallets) { wallet in
                Button {
                    selectedWallet = wallet
                } label: {
                    WalletRow(wallet: wallet)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        walletToDelete = wallet
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .refreshable {
            await viewModel.refreshBalances(wallets: wallets)
        }
    }

    /// What remains of the portfolio header. A failed refresh and a stale figure
    /// are the two things a glance at the rows cannot reveal on its own.
    /// Centred rather than leading: it is the only thing in its row, so it
    /// balances against the centred navigation title above it.
    private var statusLine: some View {
        StaleStamp(updated: oldestUpdate, didFail: viewModel.lastRefreshFailed)
            .frame(maxWidth: .infinity)
    }

    /// Pinned rather than scrolled: `safeAreaInset` also insets the list content,
    /// so the last card can still be reached.
    private var quoteFooter: some View {
        VStack(spacing: 6) {
            Image(systemName: "quote.opening")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.tertiaryLabel)
                .accessibilityHidden(true)

            Text(Quotes.current)
                .font(.system(size: 14))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiaryLabel)
        }
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 64)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("Your stack begins\nwith one address.")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.secondaryLabel)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                showAddWallet = true
            } label: {
                Text("Add Wallet")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.brand)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .overlay(
                        Capsule()
                            .strokeBorder(.brand.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
