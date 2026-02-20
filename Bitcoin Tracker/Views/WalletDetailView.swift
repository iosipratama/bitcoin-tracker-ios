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
            .padding()
        }
        .background(Color(hex: 0x0A0A0A))
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
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundStyle(.white)

            Text(viewModel.formattedBTC(wallet.totalBTC))
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                    .foregroundStyle(.secondary)

                Text("No Addresses")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Add a Bitcoin address to track its balance.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.white)

                if let error = address.fetchError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.8))
                } else {
                    Text(viewModel.formattedBTC(address.balanceBTC))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if address.fetchError == nil {
                Text(viewModel.formattedFiat(viewModel.fiatValue(btc: address.balanceBTC)))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
        .onTapGesture {
            UIPasteboard.general.string = address.address
        }
    }
}
