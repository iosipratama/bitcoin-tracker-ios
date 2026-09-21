import SwiftUI

/// Name, goal, colour and symbol pickers. Shared by the add-wallet flow and by
/// editing an existing wallet, so the two can't drift apart.
struct WalletCustomizer: View {
    @Binding var name: String
    @Binding var accent: WalletAccent
    @Binding var symbol: WalletSymbol
    @Binding var goalEnabled: Bool
    @Binding var goalText: String

    @FocusState private var goalFieldFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    /// Rounder than the cards elsewhere in the app. These three sit stacked and
    /// nearly touching, and the softer corner is what keeps them reading as
    /// separate surfaces rather than one long slab.
    private let sectionRadius: CGFloat = 32

    /// Concentric with `sectionRadius` across the field's 12pt inset, so the
    /// two curves stay parallel.
    private let fieldRadius: CGFloat = 20

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

            VStack(spacing: 6) {
                goalCard
                accentGrid
                symbolGrid
            }
        }
    }

    private var goalCard: some View {
        VStack(spacing: 0) {
            goalRow

            if goalEnabled {
                goalField
            }
        }
        .background(
            RoundedRectangle(cornerRadius: sectionRadius, style: .continuous)
                .fill(.groupedBackground)
        )
        .animation(.smooth, value: goalEnabled)
    }

    private var goalRow: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(.cardBackground)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(.iconTarget)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.label)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Goal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.label)

                Text("Track progress toward a target")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle("Goal", isOn: $goalEnabled)
                .labelsHidden()
                .tint(.brand)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(.rect)
        .onTapGesture { goalEnabled.toggle() }
    }

    private var goalField: some View {
        HStack(spacing: 8) {
            Text("\u{20BF}")
                .font(.walletBalanceMark)
                .foregroundStyle(Custom.labelTertiary)

            TextField("", text: $goalText, prompt: goalPrompt)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.label)
                .keyboardType(.decimalPad)
                .tint(.brand)
                .focused($goalFieldFocused)
                .onChange(of: goalText) { _, newValue in
                    let cleaned = Self.sanitize(newValue)
                    if cleaned != newValue { goalText = cleaned }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: fieldRadius, style: .continuous)
                .fill(Custom.backgroundBase)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .onAppear { goalFieldFocused = goalText.isEmpty }
    }

    private var goalPrompt: Text {
        Text("0.00")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Custom.labelQuaternary)
    }

    /// The decimal pad still offers whatever separator the locale uses, and a
    /// paste can carry anything at all, so the field polices itself: digits and
    /// one separator, never more than eight decimals.
    private static func sanitize(_ raw: String) -> String {
        var result = ""
        var separatorSeen = false
        var decimals = 0

        for character in raw {
            if character.isNumber {
                if separatorSeen {
                    guard decimals < 8 else { continue }
                    decimals += 1
                }
                result.append(character)
            } else if character == "." || character == "," {
                guard !separatorSeen else { continue }
                separatorSeen = true
                result.append(".")
            }
        }

        return result
    }

    private var namePrompt: Text {
        Text("Wallet name")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(Custom.labelQuaternary)
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
            RoundedRectangle(cornerRadius: sectionRadius, style: .continuous)
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
            RoundedRectangle(cornerRadius: sectionRadius, style: .continuous)
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
