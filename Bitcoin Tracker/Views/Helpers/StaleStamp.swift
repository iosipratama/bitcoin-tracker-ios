import SwiftUI

/// Shown only when the last refresh reached nothing. A successful refresh needs
/// no announcement — the balance on screen is the confirmation — so this renders
/// nothing at all in the common case.
///
/// When it does appear it still carries how old the figure is, which is the part
/// worth knowing while offline. The marker says the refresh failed rather than
/// claiming anything about the connection: the explorer can be unreachable on a
/// perfectly healthy network, so a wifi glyph here would often be a lie.
struct StaleStamp: View {
    /// nil before anything has ever loaded — on a first launch with no network
    /// there is no timestamp, and staying silent would leave a wallet reading
    /// zero with nothing to explain it.
    let updated: Date?
    let didFail: Bool

    var body: some View {
        if didFail {
            HStack(spacing: 4) {
                Text(text)

                Image(systemName: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
            }
            .font(.system(size: 12))
            .foregroundStyle(.tertiaryLabel)
            // One element: the glyph alone is ambiguous to VoiceOver.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(text), couldn’t refresh")
        }
    }

    private var text: String {
        guard let updated else { return "Not updated yet" }
        return "Updated \(updated.formatted(.relative(presentation: .named)))"
    }
}
