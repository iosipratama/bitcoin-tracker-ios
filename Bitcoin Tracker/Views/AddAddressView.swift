import SwiftUI
import SwiftData

struct AddAddressView: View {
    let wallet: Wallet

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var addressText = ""
    @State private var previewBalance: Int64?
    @State private var isValidating = false
    @State private var validationError: String?

    private var isValidFormat: Bool {
        let trimmed = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.hasPrefix("1") || trimmed.hasPrefix("3") || trimmed.hasPrefix("bc1")
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

                if isValidFormat {
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

                        Text(viewModel.formattedFiat(viewModel.fiatValue(btc: btc)))
                            .font(.balanceMedium)
                            .foregroundStyle(.white)

                        Text(viewModel.formattedBTC(btc))
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
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

                if let error = validationError {
                    Text(error)
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
                    .foregroundStyle(previewBalance != nil ? Color.bitcoinOrange : Color.bitcoinOrangeDisabled)
                    .disabled(previewBalance == nil)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
    }

    private func validateAddress() async {
        let trimmed = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        isValidating = true
        validationError = nil
        previewBalance = nil

        do {
            let balance = try await BitcoinAPIService.shared.fetchBalance(for: trimmed)
            previewBalance = balance
        } catch {
            validationError = error.localizedDescription
        }

        isValidating = false
    }

    private func saveAddress() {
        let trimmed = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        let btcAddress = BitcoinAddress(address: trimmed)
        if let balance = previewBalance {
            btcAddress.balanceSatoshis = balance
            btcAddress.lastUpdated = .now
        }
        btcAddress.wallet = wallet
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
