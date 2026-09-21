import SwiftUI

/// The same progress as `GoalMilestoneBar`, small enough to sit beside a wallet
/// name. Clamped at a full turn: the ring says "there", the percentage beside it
/// says how far past.
struct GoalRing: View {
    let progress: Double
    var size: CGFloat = 22

    var trackWidth: CGFloat = 3

    /// Heavier than the track it runs on, so the distance already covered
    /// carries more weight than the distance left.
    ///
    /// Both widths are overridable rather than proportional to `size`: scaling
    /// them with the diameter turns a ring that reads well beside a wallet name
    /// into a thick donut when a widget draws it three times larger.
    var progressWidth: CGFloat = 5

    /// `progressTrack` is tuned for the filled bar on the detail screen, where
    /// a solid area carries the contrast. Drawn as a thin arc at widget size it
    /// all but disappears, so the Home Screen passes a lighter tier rather than
    /// the app quietly relighting a token it shares.
    var trackStyle: Color = .progressTrack

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackStyle, lineWidth: trackWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(.brand, style: StrokeStyle(lineWidth: progressWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        // One shared path, so the heavier arc overhangs the track evenly on
        // both sides. The inset keeps that overhang inside the frame.
        .padding(progressWidth / 2)
        .frame(width: size, height: size)
        .animation(.smooth, value: progress)
        .accessibilityHidden(true)
    }
}
