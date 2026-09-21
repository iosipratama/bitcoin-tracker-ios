import SwiftUI

/// The same progress as `GoalMilestoneBar`, small enough to sit beside a wallet
/// name. Clamped at a full turn: the ring says "there", the percentage beside it
/// says how far past.
struct GoalRing: View {
    let progress: Double
    var isHidden = false

    var size: CGFloat = 22

    private let trackWidth: CGFloat = 3

    /// Heavier than the track it runs on, so the distance already covered
    /// carries more weight than the distance left.
    private let progressWidth: CGFloat = 5

    var body: some View {
        ZStack {
            Circle()
                .stroke(.progressTrack, lineWidth: trackWidth)

            if !isHidden {
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(.brand, style: StrokeStyle(lineWidth: progressWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        // One shared path, so the heavier arc overhangs the track evenly on
        // both sides. The inset keeps that overhang inside the frame.
        .padding(progressWidth / 2)
        .frame(width: size, height: size)
        .animation(.smooth, value: progress)
        .accessibilityHidden(true)
    }
}
