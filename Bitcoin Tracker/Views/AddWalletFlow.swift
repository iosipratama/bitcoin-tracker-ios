import SwiftUI
import SwiftData

struct AddWalletFlow: View {
    @Query private var allWallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private enum Step {
        case paste, customize
    }

    @State private var step: Step = .paste
    @State private var detent: PresentationDetent = .height(380)

    @State private var address = ""
    @State private var checkedBalance: AddressBalance?
    @State private var isChecking = false
    @State private var errorMessage: String?

    @State private var name = ""
    @State private var accent: WalletAccent = .blue
    @State private var symbol: WalletSymbol = .family

    private var trimmedAddress: String {
        address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            switch step {
            case .paste: pasteStep
            case .customize: customizeStep
            }
        }
        .fontDesign(.rounded)
        .background(.appBackground)
        .presentationDetents([.height(380), .fraction(0.96)], selection: $detent)
        .presentationBackground(.appBackground)
    }

    // MARK: - Paste

    private var pasteStep: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Add wallet") { dismiss() }

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Text(trimmedAddress.isEmpty ? "Paste an address to watch" : trimmedAddress)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(trimmedAddress.isEmpty ? .tertiaryLabel : .label)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(.negative)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 0)

            pasteAction
                .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private var pasteAction: some View {
        if isChecking {
            CapsuleActionButton(title: "Checking", isBusy: true) {}
        } else {
            // PasteButton rather than a styled button over UIPasteboard: the
            // system treats it as explicit consent, so it never raises the
            // "Allow Paste?" alert that a programmatic read triggers every time.
            PasteButton(payloadType: String.self) { strings in
                guard let pasted = strings.first else { return }
                Task { await accept(pasted) }
            }
            .buttonBorderShape(.capsule)
            .labelStyle(.titleAndIcon)
            .tint(.brand)
        }
    }

    // MARK: - Customize

    private var customizeStep: some View {
        VStack(spacing: 0) {
            SheetHeader(
                title: "Customize",
                subtitle: BitcoinAddress(address: trimmedAddress).shortAddress,
                onClose: { dismiss() },
                onConfirm: save,
                canConfirm: canSave
            )

            ScrollView {
                WalletCustomizer(name: $name, accent: $accent, symbol: $symbol)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Actions

    private func accept(_ pasted: String) async {
        address = pasted
        errorMessage = nil
        checkedBalance = nil

        let candidate = pasted.trimmingCharacters(in: .whitespacesAndNewlines)

        guard BitcoinAddress.isValidFormat(candidate) else {
            errorMessage = "That doesn’t look like a Bitcoin address."
            return
        }

        if let owner = Wallet.owner(of: candidate, in: allWallets) {
            errorMessage = "This address is already tracked in “\(owner.name)”."
            return
        }

        isChecking = true
        defer { isChecking = false }

        do {
            checkedBalance = try await BitcoinAPIService.shared.fetchBalance(for: candidate)
        } catch APIError.invalidAddress {
            errorMessage = "No such address on the Bitcoin network."
            return
        } catch {
            // A transport failure is not a verdict on the address. Adding one
            // already works offline; the balance arrives on the next refresh.
            checkedBalance = nil
        }

        advanceToCustomize()
    }

    private func advanceToCustomize() {
        symbol = Wallet.defaultSymbol(for: trimmedAddress)
        accent = Wallet.defaultAccent(for: trimmedAddress)
        withAnimation(.smooth) {
            step = .customize
            detent = .fraction(0.96)
        }
    }

    private func save() {
        guard canSave else { return }

        let wallet = Wallet(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        wallet.symbol = symbol
        wallet.accent = accent

        let btcAddress = BitcoinAddress(address: trimmedAddress)
        if let checkedBalance {
            btcAddress.apply(checkedBalance)
        }
        wallet.addresses.append(btcAddress)

        modelContext.insert(wallet)
        dismiss()
    }
}

/// Editing an existing wallet's name, colour and symbol.
struct EditWalletView: View {
    @Bindable var wallet: Wallet
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var accent: WalletAccent = .blue
    @State private var symbol: WalletSymbol = .family

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(
                title: "Customize",
                onClose: { dismiss() },
                onConfirm: save,
                canConfirm: canSave
            )

            ScrollView {
                WalletCustomizer(name: $name, accent: $accent, symbol: $symbol)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
            }
        }
        .fontDesign(.rounded)
        .background(.appBackground)
        .presentationDetents([.fraction(0.96)])
        .presentationBackground(.appBackground)
        .task {
            // Seeded once on appear: reading straight from the model would make
            // every keystroke a write.
            name = wallet.name
            accent = wallet.accent
            symbol = wallet.symbol
        }
    }

    private func save() {
        guard canSave else { return }
        wallet.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        wallet.accent = accent
        wallet.symbol = symbol
        dismiss()
    }
}
