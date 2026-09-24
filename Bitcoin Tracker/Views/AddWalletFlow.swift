import SwiftUI
import SwiftData

struct AddWalletFlow: View {
    @Query private var allWallets: [Wallet]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    private enum Step {
        case paste, customize
    }

    @State private var step: Step = .paste
    @State private var detent: PresentationDetent = .height(380)

    @State private var address = ""
    @State private var checkedBalance: AddressBalance?
    @State private var isChecking = false
    @State private var errorMessage: String?
    @State private var rejectedAddress = ""
    @FocusState private var isAddressFocused: Bool

    @State private var name = ""
    @State private var accent: WalletAccent = .blue
    @State private var symbol: WalletSymbol = .family
    @State private var goalEnabled = false
    @State private var goalText = ""

    private var trimmedAddress: String {
        address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The limit is part of `canSave` rather than a guard inside `save()`, so
    /// the confirm button greys out instead of silently doing nothing.
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && store.canAddWallet(existing: allWallets.count)
            && hasUsableGoal
    }

    /// A goal switched on but left blank would be dropped on save without
    /// saying so, so the confirm button waits for it.
    private var hasUsableGoal: Bool {
        !goalEnabled || Wallet.goalSatoshis(fromBTCText: goalText) != nil
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
                addressField

                if let errorMessage, rejectedAddress == address {
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

    /// A field, not a label: people tap the grey prompt to paste into it before
    /// they look for the button. A paste lands as one multi-character change and
    /// goes straight on, like the button; so does Return, which a vertical field
    /// delivers as a newline rather than through onSubmit.
    private var addressField: some View {
        TextField("", text: $address, prompt: addressPrompt, axis: .vertical)
            .font(.system(size: address.count > 44 ? 22 : 26, weight: .semibold))
            .foregroundStyle(Custom.labelPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(1...3)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.asciiCapable)
            .submitLabel(.continue)
            .focused($isAddressFocused)
            .disabled(isChecking)
            .accessibilityLabel("Bitcoin address")
            .onChange(of: address) { old, new in
                // `accept` writes the field too; by the time that change lands
                // it is either checking the address or has rejected it.
                guard !isChecking, new != rejectedAddress else { return }
                let submitted = new.contains(where: \.isNewline)
                guard submitted || new.count - old.count > 1 else { return }
                Task { await accept(new) }
            }
    }

    private var addressPrompt: Text {
        Text("Paste an address to watch")
            .foregroundStyle(Custom.labelQuaternary)
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
                WalletCustomizer(
                    name: $name,
                    accent: $accent,
                    symbol: $symbol,
                    goalEnabled: $goalEnabled,
                    goalText: $goalText
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Actions

    private func accept(_ pasted: String) async {
        // An address never contains whitespace, so any there came from the
        // clipboard or the field's Return and can go.
        let candidate = pasted.filter { !$0.isWhitespace }
        address = candidate
        isAddressFocused = false
        errorMessage = nil
        checkedBalance = nil

        guard !candidate.isEmpty else { return }

        guard BitcoinAddress.isValidFormat(candidate) else {
            reject(candidate, "That doesn’t look like a Bitcoin address.")
            return
        }

        if let owner = Wallet.owner(of: candidate, in: allWallets) {
            reject(candidate, "This address is already tracked in “\(owner.name)”.")
            return
        }

        isChecking = true
        defer { isChecking = false }

        do {
            checkedBalance = try await BitcoinAPIService.shared.fetchBalance(for: candidate)
        } catch APIError.invalidAddress {
            reject(candidate, "No such address on the Bitcoin network.")
            return
        } catch {
            // A transport failure is not a verdict on the address. Adding one
            // already works offline; the balance arrives on the next refresh.
            checkedBalance = nil
        }

        advanceToCustomize()
    }

    /// Kept with the address it was about, so editing the field clears it
    /// without the edit having to be told apart from `accept` setting it.
    private func reject(_ candidate: String, _ message: String) {
        rejectedAddress = candidate
        errorMessage = message
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
        wallet.goalSatoshis = goalEnabled ? Wallet.goalSatoshis(fromBTCText: goalText) : nil

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
    @State private var goalEnabled = false
    @State private var goalText = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!goalEnabled || Wallet.goalSatoshis(fromBTCText: goalText) != nil)
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
                WalletCustomizer(
                    name: $name,
                    accent: $accent,
                    symbol: $symbol,
                    goalEnabled: $goalEnabled,
                    goalText: $goalText
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .fontDesign(.rounded)
        .background(.appBackground)
        .presentationSizing(.fitted)
        .presentationBackground(.appBackground)
        .task {
            // Seeded once on appear: reading straight from the model would make
            // every keystroke a write.
            // Untransacted, the goal card would animate open the moment the
            // sheet appears, as though someone had just switched it on.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                name = wallet.name
                accent = wallet.accent
                symbol = wallet.symbol
                goalEnabled = wallet.hasGoal
                goalText = wallet.goalEditText
            }
        }
    }

    private func save() {
        guard canSave else { return }
        wallet.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        wallet.accent = accent
        wallet.symbol = symbol
        // Switching the goal off clears the target rather than parking it.
        wallet.goalSatoshis = goalEnabled ? Wallet.goalSatoshis(fromBTCText: goalText) : nil
        dismiss()
    }
}
