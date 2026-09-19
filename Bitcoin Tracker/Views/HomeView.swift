import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel
    @Environment(StoreManager.self) private var store

    @State private var showAddWallet = false
    @State private var showSettings = false
    @State private var walletToDelete: Wallet? = nil
    @State private var selectedWallet: Wallet? = nil
    @State private var showPaywall = false

    #if DEBUG
    @AppStorage(AppStorageKey.forcesEmptyState) private var forcesEmptyState = false
    #endif

    /// Checked before the sheet opens rather than at save, so nobody pastes an
    /// address and names a wallet only to be turned away at the end.
    private var canAddWallet: Bool {
        store.canAddWallet(existing: wallets.count)
    }

    /// Debug builds can pin this on to inspect the empty state without having
    /// to delete a wallet to get there.
    private var showsEmptyState: Bool {
        #if DEBUG
        return forcesEmptyState || wallets.isEmpty
        #else
        return wallets.isEmpty
        #endif
    }

    /// The oldest successful fetch across the portfolio — the honest answer to
    /// "how current is this number?"
    private var oldestUpdate: Date? {
        wallets.flatMap(\.addresses).compactMap(\.lastUpdated).min()
    }

    var body: some View {
        NavigationStack {
            Group {
                if showsEmptyState {
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
                        .tint(Custom.labelSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.brand)
                            .scaleEffect(0.8)
                            .accessibilityLabel("Refreshing balances")
                    } else {
                        Button("Add Wallet", systemImage: "plus") {
                            if canAddWallet { showAddWallet = true } else { showPaywall = true }
                        }
                        .tint(.brand)
                    }
                }
            }
            .navigationDestination(item: $selectedWallet) { wallet in
                WalletDetailView(wallet: wallet)
            }
            .sheet(isPresented: $showAddWallet) { AddWalletFlow() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
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
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 16, trailing: 20))
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
        .contentMargins(.top, 16, for: .scrollContent)
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
                .accessibilityHidden(true)

            Text(Quotes.current)
                .font(.system(size: 14))
                .italic()
                .multilineTextAlignment(.center)
        }
        // Set once for the pair: the mark and the line it opens are one thing,
        // and stating it twice is how they drift apart.
        .foregroundStyle(Custom.labelQuaternary)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 64)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }

    /// No button of its own: the copy points at the toolbar's plus, which is
    /// where adding a wallet lives everywhere else in the app.
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No wallets yet")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Custom.labelPrimary)

            Text("Tap + to add an address and name it.")
                .font(.system(size: 16, weight: .light))
                .tracking(0.34)
                .foregroundStyle(Custom.labelSecondary)
                // A layer opacity in the design, on top of the already
                // translucent label token.
                .opacity(0.8)
        }
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 58)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No wallets yet. Use the Add Wallet button to add an address and name it.")
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
