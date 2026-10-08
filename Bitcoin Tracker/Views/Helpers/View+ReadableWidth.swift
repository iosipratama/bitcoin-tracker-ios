import SwiftUI

extension View {
    /// Holds content to a column and centres the column in whatever room is
    /// left, so an iPad shows a page rather than a stretched phone.
    func readableWidth(_ width: CGFloat = .readableContent, alignment: Alignment = .center) -> some View {
        frame(maxWidth: width, alignment: alignment)
            .frame(maxWidth: .infinity)
    }
}
