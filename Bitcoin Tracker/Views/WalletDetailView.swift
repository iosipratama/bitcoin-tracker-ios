import SwiftUI
import SwiftData

struct WalletDetailView: View {
    @Bindable var wallet: Wallet
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showAddAddress = false
    @State private var showCustomize = false

    /// The glow's frame is twice this, so the falloff reaches clear exactly at
    /// the edges. A radius larger than the frame's half-height leaves the
    /// gradient still coloured where it gets cut, which shows as a hard line.
    private let glowRadius: CGFloat = 150

    private var oldestUpdate: Date? {
        wallet.addresses.compactMap(\.lastUpdated).min()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                walletHeader
                goalSection
                addressList
            }
            .padding(.bottom, 40)
        }
        .softScrollEdge(for: .top)
        .fontDesign(.rounded)
        .background(.appBackground)
        .navigationTitle(wallet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Add Address", systemImage: "plus") { showAddAddress = true }
                    Button("Customize", systemImage: "paintbrush") { showCustomize = true }
                } label: {
                    // Without this the item reserves width for the title it
                    // never draws, which nudges the centred nav title off-axis.
                    Label("Wallet actions", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                }
                .tint(.brand)
            }
        }
        .sheet(isPresented: $showAddAddress) {
            AddAddressView(wallet: wallet)
        }
        .sheet(isPresented: $showCustomize) {
            EditWalletView(wallet: wallet)
        }
    }

    private var walletHeader: some View {
        ZStack {
            // Tinted with the wallet's own accent rather than the app's, so the
            // screen reads as a continuation of the card that opened it.
            RadialGradient(
                colors: [wallet.accent.color.opacity(0.12), .clear],
                center: .center,
                startRadius: 0,
                endRadius: glowRadius
            )
            .frame(height: glowRadius * 2)

            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(wallet.accent.color)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: wallet.symbol.systemName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.onAccent)
                    }
                    .accessibilityHidden(true)

                // Same prefix/suffix the card asks for, so BTC and satoshi modes
                // are marked identically in both places.
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let prefix = viewModel.amountPrefix {
                        Text(prefix)
                            .font(.walletTotal)
                            .foregroundStyle(.secondaryLabel)
                    }

                    Text(viewModel.formattedAmount(btc: wallet.totalBTC))
                        .font(.walletTotal)
                        .foregroundStyle(.label)

                    if let suffix = viewModel.amountSuffix {
                        Text(suffix)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.secondaryLabel)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 24)

                fiatLine

                if wallet.balance.hasPending {
                    Text("\(viewModel.formattedPending(wallet.balance.pendingSatoshis)) pending confirmation")
                        .font(.system(size: 13))
                        .foregroundStyle(.brand)
                }
            }
            .padding(.vertical, 40)
            .accessibilityElement(children: .combine)
        }
    }

    /// Mirrors the card: the ≡ marker, and nothing at all when fiat is off.
    @ViewBuilder
    private var fiatLine: some View {
        if viewModel.showFiat {
            if viewModel.isFiatAvailable {
                HStack(spacing: 6) {
                    Text("\u{2261}")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.tertiaryLabel)

                    Group {
                        // A masked figure is no longer a number, and the
                        // numeric content transition has nothing to roll.
                        if viewModel.hidesBalances {
                            Text(viewModel.formattedFiatWhole(viewModel.fiatValue(btc: wallet.totalBTC)))
                        } else {
                            AnimatingNumber(value: viewModel.fiatValue(btc: wallet.totalBTC)) { value in
                                viewModel.formattedFiatWhole(value)
                            }
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondaryLabel)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 24)
            } else {
                Text("Price unavailable")
                    .font(.system(size: 15))
                    .foregroundStyle(.tertiaryLabel)
            }
        }
    }

    @ViewBuilder
    private var goalSection: some View {
        if let progress = wallet.goalProgress, let goalBTC = wallet.goalBTC {
            VStack(alignment: .leading, spacing: 10) {
                Text("Goal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondaryLabel)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if let prefix = viewModel.amountPrefix {
                            Text(prefix)
                                .font(.walletBalanceMark)
                                .foregroundStyle(Custom.labelTertiary)
                        }

                        Text(viewModel.formattedAmount(btc: goalBTC))
                            .font(.walletBalance)
                            .foregroundStyle(.label)

                        if let suffix = viewModel.amountSuffix {
                            Text(suffix)
                                .font(.walletFiat)
                                .foregroundStyle(Custom.labelTertiary)
                        }

                        Spacer(minLength: 8)

                        Text(viewModel.formattedGoalPercent(progress))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.brand)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                    GoalMilestoneBar(progress: progress)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                        .fill(.groupedBackground)
                )
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            // Pairs with the address section's own 8 to put 16 between them.
            .padding(.bottom, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Goal")
            .accessibilityValue("\(viewModel.formattedGoalPercent(progress)) of \(viewModel.formattedBTC(goalBTC))")
        }
    }

    @ViewBuilder
    private var addressList: some View {
        if wallet.addresses.isEmpty {
            VStack(spacing: 10) {
                Text("No addresses yet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondaryLabel)

                Text("Add a Bitcoin address to start tracking.")
                    .font(.system(size: 15))
                    .foregroundStyle(.tertiaryLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 48)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(wallet.addresses.count == 1 ? "Address" : "Addresses")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondaryLabel)

                    Spacer()

                    StaleStamp(updated: oldestUpdate, didFail: viewModel.lastRefreshFailed)
                }
                .padding(.horizontal, 20)

                // Cards rather than full-bleed rows with hairlines, matching the
                // wallet list and settings.
                VStack(spacing: 10) {
                    ForEach(wallet.addresses) { address in
                        AddressRow(address: address, viewModel: viewModel)
                            .contextMenu {
                                Button("Copy Address", systemImage: "doc.on.doc") {
                                    UIPasteboard.general.string = address.address
                                }
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    deleteAddress(address)
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
        }
    }

    private func deleteAddress(_ address: BitcoinAddress) {
        wallet.addresses.removeAll { $0.id == address.id }
        modelContext.delete(address)
    }
}

struct AddressRow: View {
    let address: BitcoinAddress
    let viewModel: PortfolioViewModel

    @State private var didCopy = false

    /// A stale figure is still a true one; only an address that has never
    /// resolved has nothing to show.
    private var hasEverLoaded: Bool { address.lastUpdated != nil }

    /// The balance, or the reason there isn't one yet.
    @ViewBuilder private var balanceLine: some View {
        if hasEverLoaded {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let prefix = viewModel.amountPrefix {
                    Text(prefix)
                        .font(.walletBalanceMark)
                        .foregroundStyle(Custom.labelTertiary)
                }

                Text(viewModel.formattedAmount(btc: address.balance.totalBTC))
                    .font(.walletBalance)
                    .foregroundStyle(.label)

                if let suffix = viewModel.amountSuffix {
                    Text(suffix)
                        .font(.walletFiat)
                        .foregroundStyle(Custom.labelTertiary)
                }

                if address.balance.hasPending {
                    Text("\(viewModel.formattedPending(address.pendingSatoshis)) pending")
                        .font(.system(size: 12))
                        .foregroundStyle(.brand)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else if let error = address.fetchError {
            Text(error)
                .font(.system(size: 13))
                .foregroundStyle(.tertiaryLabel)
        }
    }

    /// The fiat equivalent, which the copy confirmation borrows while it shows.
    @ViewBuilder private var trailingLine: some View {
        if didCopy {
            Label("Copied", systemImage: "checkmark")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.brand)
                .transition(.opacity)
        } else if hasEverLoaded, viewModel.showsFiatValues {
            HStack(spacing: 2) {
                Text("\u{2261}")
                    .font(.walletFiat)
                    .foregroundStyle(Custom.labelTertiary)

                Text(viewModel.formattedFiatWhole(viewModel.fiatValue(btc: address.balance.totalBTC)))
                    .font(.walletFiat)
                    .foregroundStyle(Custom.labelTertiary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
    }

    var body: some View {
        Button {
            UIPasteboard.general.string = address.address
            withAnimation(.snappy) { didCopy = true }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // Tracked wide rather than monospaced: a truncated address is
                // checked character by character, and the letter spacing gives
                // the eye the same footholds without leaving the rounded face.
                Text(address.shortAddress)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.label)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    balanceLine

                    Spacer(minLength: 8)

                    trailingLine
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: .cardInsetRadius, style: .continuous)
                    .fill(.groupedBackground)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: didCopy)
        .task(id: didCopy) {
            guard didCopy else { return }
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.smooth) { didCopy = false }
        }
        .accessibilityLabel("Address \(address.address)")
        .accessibilityValue(hasEverLoaded
            ? viewModel.formattedBTC(address.balance.totalBTC)
            : (address.fetchError ?? "Not loaded"))
        .accessibilityHint("Copies the address")
    }
}

#Preview("With Addresses") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)

    let wallet = Wallet(name: "Personal Wallet")
    let address1 = BitcoinAddress(address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh")
    address1.balanceSatoshis = 50_000_000
    address1.lastUpdated = .now

    let address2 = BitcoinAddress(address: "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
    address2.balanceSatoshis = 100_000_000
    address2.lastUpdated = .now

    wallet.addresses = [address1, address2]
    container.mainContext.insert(wallet)

    let viewModel = PortfolioViewModel()

    return WalletDetailView(wallet: wallet)
        .modelContainer(container)
        .environment(viewModel)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)

    let wallet = Wallet(name: "Cold Storage")
    container.mainContext.insert(wallet)

    let viewModel = PortfolioViewModel()

    return WalletDetailView(wallet: wallet)
        .modelContainer(container)
        .environment(viewModel)
}

#Preview("Address Row") {
    let address = BitcoinAddress(address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh")
    address.balanceSatoshis = 50_000_000
    address.lastUpdated = .now

    let viewModel = PortfolioViewModel()

    return VStack(spacing: 0) {
        Rectangle().fill(Color.divider).frame(height: 0.5)
        AddressRow(address: address, viewModel: viewModel)
        Rectangle().fill(Color.divider).frame(height: 0.5)
    }
    .background(Color.appBackground)
}
