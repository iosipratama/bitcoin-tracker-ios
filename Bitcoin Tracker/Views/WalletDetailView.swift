import SwiftUI
import SwiftData

struct WalletDetailView: View {
    @Bindable var wallet: Wallet
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showAddAddress = false
    @State private var showCustomize = false

    private var oldestUpdate: Date? {
        wallet.addresses.compactMap(\.lastUpdated).min()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                walletHeader
                addressList
            }
            .padding(.bottom, 40)
        }
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
                    Label("Wallet actions", systemImage: "ellipsis")
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
                colors: [wallet.accent.color.opacity(0.10), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
            .frame(height: 260)

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

                    AnimatingNumber(value: viewModel.fiatValue(btc: wallet.totalBTC)) { value in
                        viewModel.formattedFiat(value)
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
                    Text("Addresses")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondaryLabel)

                    Spacer()

                    if let updated = oldestUpdate {
                        Text("Updated \(updated, format: .relative(presentation: .named))")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiaryLabel)
                    }
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

    var body: some View {
        Button {
            UIPasteboard.general.string = address.address
            withAnimation(.snappy) { didCopy = true }
        } label: {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    // Monospaced on purpose: a truncated address is checked
                    // character by character, which proportional digits hinder.
                    Text(address.shortAddress)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(.label)

                    if let error = address.fetchError {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(.negative)
                    } else {
                        HStack(spacing: 6) {
                            Text(viewModel.formattedBTC(address.balance.totalBTC))
                                .font(.system(size: 13))
                                .foregroundStyle(.secondaryLabel)

                            if address.balance.hasPending {
                                Text("\(viewModel.formattedPending(address.pendingSatoshis)) pending")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.brand)
                            }
                        }
                    }
                }

                Spacer()

                if didCopy {
                    Label("Copied", systemImage: "checkmark")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.brand)
                        .transition(.opacity)
                } else if address.fetchError == nil, viewModel.showsFiatValues {
                    Text(viewModel.formattedFiat(viewModel.fiatValue(btc: address.balance.totalBTC)))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondaryLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
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
        .accessibilityValue(address.fetchError ?? viewModel.formattedBTC(address.balance.totalBTC))
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
