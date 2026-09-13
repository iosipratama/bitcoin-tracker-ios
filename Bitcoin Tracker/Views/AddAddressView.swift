import SwiftUI
import SwiftData

struct AddAddressView: View {
    let wallet: Wallet

    @Query private var allWallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var addressText = ""
    @State private var previewBalance: Int64?
    @State private var isValidating = false
    @State private var validationError: String?

    private var trimmedAddress: String {
        addressText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidFormat: Bool {
        BitcoinAddress.isValidFormat(trimmedAddress)
    }

    /// The same address in two places would be counted twice in every total,
    /// so an address may only live in one wallet.
    private var duplicateOwner: Wallet? {
        guard !trimmedAddress.isEmpty else { return nil }
        return allWallets.first { candidate in
            candidate.addresses.contains {
                $0.address.caseInsensitiveCompare(trimmedAddress) == .orderedSame
            }
        }
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
                        .foregroundStyle(Color.textSecondary)
                        .kerning(1.2)
                        .textCase(.uppercase)

                    TextField("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", text: $addressText)
                        .textFieldStyle(.plain)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 18)
                        .background(
                            RoundedRectangle(cornerRadius: .rowRadius)
                                .fill(Color.surfaceWarm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: .rowRadius)
                                        .strokeBorder(Color.rowDivider, lineWidth: 0.5)
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
                                    .tint(Color.bitcoinOrange)
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.subheadline)
                            }
                            Text(isValidating ? "Checking…" : "Preview Balance")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.bitcoinOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: .rowRadius)
                                .strokeBorder(Color.bitcoinOrange.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .disabled(isValidating)
                }

                if let balance = previewBalance {
                    let btc = Double(balance) / 100_000_000
                    VStack(spacing: 6) {
                        Text("Balance Preview")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .kerning(1.2)
                            .textCase(.uppercase)

                        if viewModel.showsFiatValues {
                            Text(viewModel.formattedFiat(viewModel.fiatValue(btc: btc)))
                                .font(.balanceMedium)
                                .foregroundStyle(.white)

                            Text(viewModel.formattedBTC(btc))
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        } else {
                            Text(viewModel.formattedBTC(btc))
                                .font(.balanceMedium)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: .rowRadius)
                            .fill(Color.surfaceWarm)
                            .overlay(
                                RoundedRectangle(cornerRadius: .rowRadius)
                                    .strokeBorder(Color.rowDivider, lineWidth: 0.5)
                            )
                    )
                }

                if let message = duplicateMessage ?? validationError {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.errorText)
                } else if !trimmedAddress.isEmpty && !isValidFormat {
                    Text("That doesn\u{2019}t look like a Bitcoin address.")
                        .font(.caption)
                        .foregroundStyle(Color.errorText)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 16)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAddress()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? Color.bitcoinOrange : Color.bitcoinOrangeDisabled)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
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
            btcAddress.balanceSatoshis = previewBalance
            btcAddress.lastUpdated = .now
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
