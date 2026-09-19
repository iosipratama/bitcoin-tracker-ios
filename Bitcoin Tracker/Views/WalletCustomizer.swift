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
            .foregroundStyle(FigmaPalette.labelQuaternary)
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
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.label)
                .frame(width: .sheetButton, height: .sheetButton)
                .background(Circle().fill(.groupedBackground))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

/// The primary action, mirroring `SheetCloseButton`'s metrics so the two balance
/// across the bar. Carries the capsule's colour pairing so it still reads as the
/// primary action at a fraction of the size.
struct SheetConfirmButton: View {
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.onAccent)
                .frame(width: .sheetButton, height: .sheetButton)
                // The effect rather than .glassProminent: that button style adds
                // its own padding around the label, so a 44pt label rendered
                // closer to 60 and outgrew the close button beside it.
                .glassEffect(
                    .regular
                        .tint(isEnabled ? Color.brand : Color.brandDisabled)
                        .interactive(),
                    in: .circle
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("Save")
    }
}

/// The bar at the top of a sheet. Shared so the close button, title and confirm
/// action stay aligned across every sheet that uses one.
struct SheetHeader: View {
    let title: String
    var subtitle: String?
    let onClose: () -> Void
    var onConfirm: (() -> Void)?
    var canConfirm = true

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.label)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondaryLabel)
                }
            }

            HStack {
                SheetCloseButton(action: onClose)

                Spacer()

                if let onConfirm {
                    SheetConfirmButton(isEnabled: canConfirm, action: onConfirm)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
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
