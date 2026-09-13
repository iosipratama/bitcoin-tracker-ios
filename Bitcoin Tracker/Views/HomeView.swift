import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showAddWallet = false
    @State private var showSettings = false
    @State private var walletToDelete: Wallet? = nil

    private var portfolio: AddressBalance {
        viewModel.portfolioBalance(wallets)
    }

    private var totalBTC: Double { portfolio.totalBTC }

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
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Wallets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                        .tint(Color.bitcoinOrange)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.bitcoinOrange)
                            .scaleEffect(0.8)
                            .accessibilityLabel("Refreshing balances")
                    } else {
                        Button("Add Wallet", systemImage: "plus") { showAddWallet = true }
                            .tint(Color.bitcoinOrange)
                    }
                }
            }
            .navigationDestination(for: Wallet.self) { wallet in
                WalletDetailView(wallet: wallet)
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

    // Swipe actions only exist on List rows — in a LazyVStack the modifier is silently ignored.
    private var walletList: some View {
        List {
            portfolioSummary
                .listRowInsets(EdgeInsets(top: 28, leading: 20, bottom: 32, trailing: 20))
                .listRowBackground(Color.appBackground)
                .listRowSeparator(.hidden)

            ForEach(wallets) { wallet in
                NavigationLink(value: wallet) {
                    WalletRow(wallet: wallet)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.appBackground)
                .listRowSeparatorTint(Color.rowDivider)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        walletToDelete = wallet
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.refreshBalances(wallets: wallets)
        }
    }

    private var portfolioSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .kerning(1.5)
                .textCase(.uppercase)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(totalBTC.btcDigits)
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)

                Text("BTC")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textSecondary)
            }

            if viewModel.showFiat {
                fiatSubtitle
            }

            if portfolio.hasPending {
                Text("\(viewModel.formattedPending(portfolio.pendingSatoshis)) pending confirmation")
                    .font(.caption)
                    .foregroundStyle(Color.bitcoinOrange)
            }

            if let error = viewModel.balanceError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.errorText)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let oldestUpdate {
                Text("Updated \(oldestUpdate, format: .relative(presentation: .named))")
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var fiatSubtitle: some View {
        if viewModel.isFiatAvailable {
            Text(viewModel.formattedFiat(viewModel.fiatValue(btc: totalBTC)))
                .font(.system(size: 17))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else {
            Text("Price unavailable")
                .font(.system(size: 15))
                .foregroundStyle(Color.textSecondary.opacity(0.7))
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
