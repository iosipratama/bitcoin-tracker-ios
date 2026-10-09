import SwiftUI
import SwiftData
import StoreKit

struct HomeView: View {
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel
    @Environment(StoreManager.self) private var store
    @Environment(WidgetRouter.self) private var router
    @Environment(\.requestReview) private var requestReview
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showAddWallet = false
    @State private var showSettings = false
    @State private var walletToDelete: Wallet? = nil
    @State private var selectedWallet: Wallet? = nil
    @State private var showPaywall = false
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    /// Seeded on first appearance so the query resolving on a cold launch
    /// doesn't read as a wallet having just been created.
    @State private var knownWalletCount: Int?

    #if DEBUG
    @Environment(ActivityStore.self) private var activity
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
        wallets.flatMap(\.addressList).compactMap(\.lastUpdated).min()
    }

    /// Read from the window, not from inside a column: the sidebar reports
    /// compact even on the widest iPad.
    private var showsColumns: Bool { horizontalSizeClass == .regular }

    var body: some View {
        // Collapses to a single stack on iPhone and in a narrow iPad window,
        // so there is one navigation model rather than one per device.
        NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: $compactColumn) {
            sidebar
                .navigationSplitViewColumnWidth(min: 360, ideal: 400, max: 440)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        // On the split view rather than the sidebar, which collapsed on iPhone
        // reappears on every Back and would refetch each time.
        .task {
            #if DEBUG
            if ScreenshotScene.current != nil {
                await applyScreenshotScene()
                return
            }
            #endif
            await refresh()
        }
    }

    #if DEBUG
    private func applyScreenshotScene() async {
        // Fixed balances and history, and no balance fetch: a screenshot
        // shouldn't depend on what four busy addresses did this minute.
        if ScreenshotScene.loadsSampleWallets {
            let wallets = SampleWallet.replaceAll(in: modelContext, demo: true)
            for (wallet, sample) in zip(wallets, SampleWallet.all) {
                activity.seed(wallet, items: SampleWallet.demoActivity(for: sample))
            }
            // Lets the query pick up the inserts before anything is selected.
            try? await Task.sleep(for: .milliseconds(300))
        }
        await viewModel.refreshPrices()

        switch ScreenshotScene.current {
        case .detail:
            if wallets.count > 2 { open(wallets[2]) }
        case .addWallet:
            showAddWallet = true
        case .settings:
            showSettings = true
        case .home, nil:
            break
        }
    }
    #endif

    private var sidebar: some View {
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
        .sheet(isPresented: $showAddWallet) { AddWalletFlow() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: router.requestedWalletID, initial: true) { _, _ in
            openRequestedWallet()
        }
        .onChange(of: wallets.count, initial: true) { _, count in
            // Also tried here: a cold launch from a widget can arrive
            // before the query has resolved, and the id has to keep until
            // there is a wallet to match it against.
            openRequestedWallet()
            selectFirstWalletIfShowingColumns()

            defer { knownWalletCount = count }
            guard let known = knownWalletCount, count > known else { return }
            Task { await askForReviewIfEarned() }
        }
        .alert("Remove \(walletToDelete?.name ?? "wallet")?", isPresented: .init(
            get: { walletToDelete != nil },
            set: { if !$0 { walletToDelete = nil } }
        )) {
            Button("Remove", role: .destructive) {
                if let wallet = walletToDelete {
                    // Cleared first so the detail column never draws a
                    // wallet that's already gone.
                    if selectedWallet == wallet { selectedWallet = nil }
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
        .onChange(of: showsColumns) { selectFirstWalletIfShowingColumns() }
    }

    /// With two columns there is always room for a wallet, and an empty right
    /// half reads as something failing to load.
    @ViewBuilder
    private var detail: some View {
        if let selectedWallet {
            WalletDetailView(wallet: selectedWallet)
                .id(selectedWallet.persistentModelID)
        } else {
            Text(wallets.isEmpty ? "" : "Select a wallet")
                .font(.system(size: 17, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundStyle(Custom.labelQuaternary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.appBackground)
        }
    }

    private func open(_ wallet: Wallet) {
        selectedWallet = wallet
        compactColumn = .detail
    }

    private func selectFirstWalletIfShowingColumns() {
        guard showsColumns else { return }
        if let selectedWallet, wallets.contains(selectedWallet) { return }
        selectedWallet = wallets.first
    }

    /// The wallet a tapped widget asked for, once the query has one to show.
    /// A request for a wallet that no longer exists is dropped rather than
    /// held, so a deleted wallet can't sit there hijacking the next launch.
    private func openRequestedWallet() {
        guard let id = router.requestedWalletID, !wallets.isEmpty else { return }
        if let wallet = wallets.first(where: { $0.widgetID == id }) { open(wallet) }
        router.clear()
    }

    /// Publishing after the fetch rather than before it: the snapshot is what
    /// the Home Screen reads, and there is no point handing it the same figures
    /// it already has.
    private func refresh() async {
        await viewModel.refreshBalances(wallets: wallets)
        WidgetBridge.publish(context: modelContext, formatter: viewModel.formatter)
    }

    /// Asked once, after the app has shown a real balance for a wallet the
    /// user just added. Marked before the call because the system decides
    /// whether anything appears, and a swallowed prompt shouldn't leave this
    /// armed to fire again on the next wallet.
    private func askForReviewIfEarned() async {
        guard ReviewPrompt.isEarned(wallets: wallets, refreshFailed: viewModel.lastRefreshFailed) else { return }

        try? await Task.sleep(for: ReviewPrompt.delay)
        guard !Task.isCancelled else { return }

        ReviewPrompt.markAsked()
        requestReview()
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
                    open(wallet)
                } label: {
                    WalletRow(wallet: wallet, isSelected: showsColumns && selectedWallet == wallet)
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
        .softScrollEdge(for: .top)
        .refreshable {
            await refresh()
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
        wallet.add(address)
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
