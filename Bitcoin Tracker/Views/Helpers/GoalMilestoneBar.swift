import SwiftUI

/// A goal's progress split into five milestones. Five rather than one
/// continuous bar because a fifth is a distance you can picture; a percentage
/// of a whole is not.
struct GoalMilestoneBar: View {
    let progress: Double
    var isHidden = false

    private let milestones = 5
    private let spacing: CGFloat = 6
    private let height: CGFloat = 6

    /// A goal barely begun still deserves a mark rather than an empty bar.
    private let minimumFill: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            let segment = (proxy.size.width - spacing * CGFloat(milestones - 1)) / CGFloat(milestones)

            HStack(spacing: spacing) {
                ForEach(0..<milestones, id: \.self) { index in
                    Capsule()
                        .fill(.progressTrack)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(.brand)
                                .frame(width: fillWidth(at: index, segment: segment))
                        }
                }
            }
        }
        .frame(height: height)
        .animation(.smooth, value: progress)
        .accessibilityHidden(true)
    }

    private func fillWidth(at index: Int, segment: CGFloat) -> CGFloat {
        guard !isHidden, segment > 0 else { return 0 }

        let fraction = min(max(progress * Double(milestones) - Double(index), 0), 1)
        guard fraction > 0 else { return 0 }

        return min(max(segment * fraction, minimumFill), segment)
    }
}
