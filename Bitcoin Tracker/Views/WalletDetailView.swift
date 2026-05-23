import SwiftUI
import SwiftData

struct WalletDetailView: View {
    @Bindable var wallet: Wallet
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showAddAddress = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                walletHeader
                addressList
            }
            .padding(.bottom, 40)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(wallet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddAddress = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.bitcoinOrange)
                }
            }
        }
        .sheet(isPresented: $showAddAddress) {
            AddAddressView(wallet: wallet)
        }
    }

    private var walletHeader: some View {
        ZStack {
            RadialGradient(
                colors: [Color.bitcoinOrange.opacity(0.06), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 160
            )
            .frame(height: 240)

            VStack(spacing: 10) {
                AnimatingNumber(value: viewModel.fiatValue(btc: wallet.totalBTC)) { val in
                    viewModel.formattedFiat(val)
                }
                .font(.balanceMedium)
                .foregroundStyle(.white)

                Text(viewModel.formattedBTC(wallet.totalBTC))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.vertical, 48)
        }
    }

    @ViewBuilder
    private var addressList: some View {
        if wallet.addresses.isEmpty {
            VStack(spacing: 14) {
                Text("No addresses yet.")
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(Color.textSecondary)

                Text("Add a Bitcoin address to start tracking.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary.opacity(0.6))
            }
            .padding(.top, 56)
        } else {
            VStack(spacing: 0) {
                HStack {
                    Text("Addresses")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .kerning(1.5)
                        .textCase(.uppercase)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

                Rectangle()
                    .fill(Color.rowDivider)
                    .frame(height: 0.5)

                ForEach(wallet.addresses) { address in
                    AddressRow(address: address, viewModel: viewModel)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = address.address
                            } label: {
                                Label("Copy Address", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                deleteAddress(address)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                    Rectangle()
                        .fill(Color.rowDivider)
                        .frame(height: 0.5)
                }
            }
            .padding(.top, 36)
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

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text(address.shortAddress)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.white)

                if let error = address.fetchError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(Color.errorText)
                } else {
                    Text(viewModel.formattedBTC(address.balanceBTC))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            if address.fetchError == nil {
                Text(viewModel.formattedFiat(viewModel.fiatValue(btc: address.balanceBTC)))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(Color.appBackground)
        .onTapGesture {
            UIPasteboard.general.string = address.address
        }
        .accessibilityHint("Double tap to copy address")
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
        Rectangle().fill(Color.rowDivider).frame(height: 0.5)
        AddressRow(address: address, viewModel: viewModel)
        Rectangle().fill(Color.rowDivider).frame(height: 0.5)
    }
    .background(Color.appBackground)
}
