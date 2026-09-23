import SwiftUI

extension View {
    /// The soft scroll edge on iOS 26 and later. iOS 18 has no scroll edge effect
    /// to ask for; its bars fade in their own material as content passes under.
    @ViewBuilder
    func softScrollEdge(for edges: Edge.Set) -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: edges)
        } else {
            self
        }
    }
}
