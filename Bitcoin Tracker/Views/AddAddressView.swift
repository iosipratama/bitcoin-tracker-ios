import SwiftUI
import SwiftData

struct AddAddressView: View {
    let wallet: Wallet

    @Query private var allWallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var addressText = ""
    @State private var previewBalance: AddressBalance?
    @State private var isValidating = false
    @State private var validationError: String?

    private var trimmedAddress: String {
        addressText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidFormat: Bool {
        BitcoinAddress.isValidFormat(trimmedAddress)
    }

    private var duplicateOwner: Wallet? {
        Wallet.owner(of: trimmedAddress, in: allWallets)
    }

    private var duplicateMessage: String? {
        guard let owner = duplicateOwner else { return nil }
        return owner.persistentModelID == wallet.persistentModelID
            ? "This address is already in this wallet."
            : "This address is already tracked in “\(owner.name)”."
    }

    private var canSave: Bool {
        isValidFormat && duplicateMessage == nil
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bitcoin Address")
                        .font(.caption)
                        .foregroundStyle(.secondaryLabel)
                        .kerning(1.2)
                        .textCase(.uppercase)

                    TextField("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", text: $addressText)
                        .textFieldStyle(.plain)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.label)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 18)
                        .background(
                            RoundedRectangle(cornerRadius: .rowRadius)
                                .fill(.controlFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: .rowRadius)
                                        .strokeBorder(.divider, lineWidth: 0.5)
                                )
                        )
                        .onChange(of: addressText) {
                            previewBalance = nil
                            validationError = nil
                        }
                }

                if canSave {
                    Button {
                        Task { await validateAddress() }
                    } label: {
                        HStack(spacing: 8) {
                            if isValidating {
                                ProgressView()
                                    .tint(.brand)
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.subheadline)
                            }
                            Text(isValidating ? "Checking…" : "Preview Balance")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: .rowRadius)
                                .strokeBorder(.brand.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .disabled(isValidating)
                }

                if let balance = previewBalance {
                    let btc = balance.totalBTC
                    VStack(spacing: 6) {
                        Text("Balance Preview")
                            .font(.caption)
                            .foregroundStyle(.secondaryLabel)
                            .kerning(1.2)
                            .textCase(.uppercase)

                        if viewModel.showsFiatValues {
                            Text(viewModel.formattedFiat(viewModel.fiatValue(btc: btc)))
                                .font(.walletTotal)
                                .foregroundStyle(.label)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .padding(.horizontal, 16)

                            Text(viewModel.formattedBTC(btc))
                                .font(.subheadline)
                                .foregroundStyle(.secondaryLabel)
                        } else {
                            Text(viewModel.formattedBTC(btc))
                                .font(.walletTotal)
                                .foregroundStyle(.label)
                        }

                        if balance.hasPending {
                            Text("\(viewModel.formattedPending(balance.pendingSatoshis)) pending")
                                .font(.caption)
                                .foregroundStyle(.brand)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: .rowRadius)
                            .fill(.controlFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: .rowRadius)
                                    .strokeBorder(.divider, lineWidth: 0.5)
                            )
                    )
                }

                if let message = duplicateMessage ?? validationError {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.negative)
                } else if !trimmedAddress.isEmpty && !isValidFormat {
                    Text("That doesn\u{2019}t look like a Bitcoin address.")
                        .font(.caption)
                        .foregroundStyle(.negative)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 16)
            .fontDesign(.rounded)
            .background(.appBackground)
            .navigationTitle("Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondaryLabel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAddress()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? Color.brand : Color.brandDisabled)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.appBackground)
    }

    private func validateAddress() async {
        let trimmed = trimmedAddress
        isValidating = true
        validationError = nil
        previewBalance = nil

        do {
            previewBalance = try await BitcoinAPIService.shared.fetchBalance(for: trimmed)
        } catch {
            validationError = error.localizedDescription
        }

        isValidating = false
    }

    /// Saving never requires the network — an unfetched address simply picks up its
    /// balance on the next refresh.
    private func saveAddress() {
        guard canSave else { return }

        let btcAddress = BitcoinAddress(address: trimmedAddress)
        if let previewBalance {
            btcAddress.apply(previewBalance)
        }
        // SwiftData maintains the inverse; setting both sides can duplicate the row.
        wallet.addresses.append(btcAddress)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, BitcoinAddress.self, configurations: config)

    let wallet = Wallet(name: "Test Wallet")
    container.mainContext.insert(wallet)

    let viewModel = PortfolioViewModel()

    return AddAddressView(wallet: wallet)
        .modelContainer(container)
        .environment(viewModel)
}
