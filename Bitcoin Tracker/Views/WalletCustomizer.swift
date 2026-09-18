import SwiftUI

/// Name, colour and symbol pickers. Shared by the add-wallet flow and by editing
/// an existing wallet, so the two can't drift apart.
struct WalletCustomizer: View {
    @Binding var name: String
    @Binding var accent: WalletAccent
    @Binding var symbol: WalletSymbol

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        VStack(spacing: 20) {
            TextField("", text: $name, prompt: namePrompt)
                .font(.system(size: 26, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundStyle(.label)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.vertical, 8)

            accentGrid
            symbolGrid
        }
    }

    private var namePrompt: Text {
        Text("Wallet name")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(.tertiaryLabel)
    }

    private var accentGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(WalletAccent.allCases) { option in
                Button {
                    accent = option
                } label: {
                    Circle()
                        .fill(option.color)
                        .frame(height: 44)
                        .overlay {
                            if option == accent {
                                Circle().strokeBorder(.label, lineWidth: 2).padding(-4)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.rawValue)
                .accessibilityAddTraits(option == accent ? .isSelected : [])
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                .fill(.groupedBackground)
        )
    }

    private var symbolGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(WalletSymbol.allCases) { option in
                Button {
                    symbol = option
                } label: {
                    Circle()
                        .fill(.cardBackground)
                        .frame(height: 44)
                        .overlay {
                            Image(systemName: option.systemName)
                                .font(.system(size: 17))
                                .foregroundStyle(.label)
                        }
                        .overlay {
                            if option == symbol {
                                Circle().strokeBorder(.label, lineWidth: 2).padding(-4)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.rawValue)
                .accessibilityAddTraits(option == symbol ? .isSelected : [])
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                .fill(.groupedBackground)
        )
    }
}

/// The circular close button both sheets use.
struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.label)
                .frame(width: 34, height: 34)
                .background(Circle().fill(.groupedBackground))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

/// The brand-orange capsule used for the primary action in these sheets.
struct CapsuleActionButton: View {
    let title: String
    var isBusy = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isBusy {
                    ProgressView()
                        .tint(.onAccent)
                        .controlSize(.small)
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .fontDesign(.rounded)
            }
            .foregroundStyle(.onAccent)
            .padding(.vertical, 15)
            .padding(.horizontal, 44)
            .background(
                Capsule().fill(isEnabled ? Color.brand : Color.brandDisabled)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isBusy)
    }
}
