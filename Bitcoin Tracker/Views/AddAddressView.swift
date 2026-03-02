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
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bitcoin Address")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)

                    TextField("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", text: $addressText)
                        .textFieldStyle(.plain)
                        .font(.subheadline.monospaced())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: .rowRadius)
                                .fill(Color.white.opacity(0.05))
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
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .tint(Color.bitcoinOrange)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(isValidating ? "Checking..." : "Preview Balance")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.bitcoinOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: .rowRadius)
                                .strokeBorder(Color.bitcoinOrange.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .disabled(isValidating)
                }

                if let balance = previewBalance {
                    let btc = Double(balance) / 100_000_000
                    VStack(spacing: 8) {
                        Text("Balance Preview")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)

                        Text(viewModel.formattedBTC(btc))
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Text(viewModel.formattedFiat(viewModel.fiatValue(btc: btc)))
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: .rowRadius)
                            .fill(Color.white.opacity(0.05))
                    )
                }

                if let error = validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.errorText)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(Color(hex: 0x0A0A0A).ignoresSafeArea())
            .navigationTitle("Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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

