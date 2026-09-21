import SwiftUI

/// The same progress as `GoalMilestoneBar`, small enough to sit beside a wallet
/// name. Clamped at a full turn: the ring says "there", the percentage beside it
/// says how far past.
struct GoalRing: View {
    let progress: Double
    var isHidden = false

    private let lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Circle()
                .stroke(.cardBackground, lineWidth: lineWidth)

            if !isHidden {
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(.brand, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .animation(.smooth, value: progress)
        .accessibilityHidden(true)
    }
}
