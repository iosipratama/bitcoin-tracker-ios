import SwiftUI
import SwiftData

struct WalletDetailView: View {
    @Bindable var wallet: Wallet
    @Environment(\.modelContext) private var modelContext
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showAddAddress = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                walletHeader
                addressList
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .background(Color(hex: 0x0A0A0A).ignoresSafeArea())
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
        VStack(spacing: 8) {
            AnimatingNumber(value: viewModel.fiatValue(btc: wallet.totalBTC)) { val in
                viewModel.formattedFiat(val)
            }
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundStyle(.white)

            Text(viewModel.formattedBTC(wallet.totalBTC))
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var addressList: some View {
        if wallet.addresses.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "key.horizontal")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.textSecondary)

                Text("No Addresses")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Add a Bitcoin address to track its balance.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, 40)
        } else {
            LazyVStack(spacing: 8) {
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
                }
                .onDelete(perform: deleteAddresses)
            }
        }
    }

    private func deleteAddress(_ address: BitcoinAddress) {
        wallet.addresses.removeAll { $0.id == address.id }
        modelContext.delete(address)
    }

    private func deleteAddresses(at offsets: IndexSet) {
        for index in offsets {
            let address = wallet.addresses[index]
            modelContext.delete(address)
        }
        wallet.addresses.remove(atOffsets: offsets)
    }
}

struct AddressRow: View {
    let address: BitcoinAddress
    let viewModel: PortfolioViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(address.shortAddress)
                    .font(.subheadline.monospaced().monospacedDigit())
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
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: .rowRadius)
                .fill(Color.white.opacity(0.04))
        )
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
    
    let wallet = Wallet(name: "Empty Wallet")
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
    
    return AddressRow(address: address, viewModel: viewModel)
        .padding()
        .background(Color(hex: 0x0A0A0A))
}

#Preview("Address Row with Error") {
    let address = BitcoinAddress(address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh")
    address.fetchError = "Network error"
    
    let viewModel = PortfolioViewModel()
    
    return AddressRow(address: address, viewModel: viewModel)
        .padding()
        .background(Color(hex: 0x0A0A0A))
}

