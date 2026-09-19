import SwiftUI

/// The full-width capsule that carries the single action on a screen that has
/// only one — the welcome screen and the paywall. Wider-set and much taller
/// than `CapsuleActionButton`, which is sized for a sheet's toolbar.
struct ProminentCapsuleButton: View {
    let title: String
    var isBusy = false
    var isEnabled = true
    let action: () -> Void

    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            HStack(spacing: 10) {
                if isBusy {
                    ProgressView()
                        .tint(.onAccent)
                        .controlSize(.small)
                }

                Text(title)
                    .font(.system(size: 17, weight: .heavy).width(.expanded))
                    .tracking(-0.48)
            }
            .foregroundStyle(.onAccent)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 94)
            .background(Capsule().fill(isEnabled ? Color.brand : Color.brandDisabled))
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isBusy)
        .padding(.horizontal, 50)
        .sensoryFeedback(.impact(weight: .medium, intensity: 1), trigger: taps)
    }
}
