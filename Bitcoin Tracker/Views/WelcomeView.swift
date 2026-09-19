import SwiftUI

/// The first thing a new user sees. Nine lines that set expectations before any
/// balance appears, then one way forward.
struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var continueTaps = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(WelcomeLine.all) { line in
                    line.text
                        .tracking(0.34)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(line.spokenText)
                }
            }
            .font(.system(size: 20, weight: .light))
            .fontDesign(.rounded)
            .foregroundStyle(FigmaPalette.labelSecondary)
            .padding(.horizontal, 32)
            .padding(.top, 36)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaInset(edge: .bottom) { continueButton }
        .background(FigmaPalette.backgroundBase)
    }

    /// Deliberately taller and wider-set than any other button in the app — it
    /// is the only thing to do on this screen.
    private var continueButton: some View {
        Button {
            continueTaps += 1
            onContinue()
        } label: {
            Text("Continue")
                .font(.system(size: 17, weight: .heavy).width(.expanded))
                .tracking(-0.48)
                .foregroundStyle(FigmaPalette.black)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 94)
                .background(Capsule().fill(FigmaPalette.accent))
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 50)
        .padding(.bottom, 46)
        .sensoryFeedback(.impact(weight: .medium, intensity: 1), trigger: continueTaps)
    }
}

// MARK: - Copy

/// One paragraph, kept as data so the wording stays readable and the view stays
/// free of a wall of `+` operators.
private struct WelcomeLine: Identifiable {
    let id: Int
    let segments: [WelcomeSegment]

    /// Concatenation is the only way to flow an SF Symbol inside wrapping text:
    /// `AttributedString` carries no attachments and Markdown can't reach a
    /// symbol. Colour and font survive the `+`; layout modifiers don't, so they
    /// are applied to the finished `Text` at the call site.
    var text: Text {
        segments.dropFirst().reduce(segments[0].text) { $0 + $1.text }
    }

    /// The arrows would otherwise reach VoiceOver as "arrow up right", fighting
    /// the sentence that already carries the word.
    var spokenText: String {
        segments.map(\.spokenText)
            .joined()
            .split(separator: " ")
            .joined(separator: " ")
    }
}

private enum WelcomeSegment {
    case plain(String)
    case bitcoin
    case symbol(String, color: Color?, spoken: String)

    /// `verbatim` throughout: this copy is not a localisation key, and it must
    /// not be run through the Markdown parser.
    var text: Text {
        switch self {
        case .plain(let string):
            Text(verbatim: string)
        case .bitcoin:
            Text(verbatim: "₿ bitcoin").foregroundStyle(.bitcoinWord)
        case .symbol(let name, let color, _):
            if let color {
                Text(Image(systemName: name)).foregroundStyle(color)
            } else {
                Text(Image(systemName: name))
            }
        }
    }

    var spokenText: String {
        switch self {
        case .plain(let string): string
        case .bitcoin: "bitcoin"
        case .symbol(_, _, let spoken): spoken
        }
    }
}

private extension WelcomeLine {
    static let all: [WelcomeLine] = [
        WelcomeLine(id: 0, segments: [
            .plain("saving in "),
            .bitcoin,
            .plain(" is not easy 📉")
        ]),
        WelcomeLine(id: 1, segments: [
            .plain("it goes up "),
            .symbol("arrow.up.right", color: .rising, spoken: ""),
            .plain("  and down "),
            .symbol("arrow.down.forward", color: .falling, spoken: ""),
            .plain(" in dollars,")
        ]),
        WelcomeLine(id: 2, segments: [
            .plain("and most apps "),
            .symbol("iphone", color: nil, spoken: ""),
            .plain(" make sure you feel every bit of it 😱")
        ]),
        WelcomeLine(id: 3, segments: [
            .plain("charts. alerts. red numbers. 😵‍💫")
        ]),
        WelcomeLine(id: 4, segments: [
            .bitcoin,
            .plain(" rewards the people who do nothing 🧘")
        ]),
        WelcomeLine(id: 5, segments: [
            .plain("and this app, sats keeper.")
        ]),
        WelcomeLine(id: 6, segments: [
            .plain("is for the "),
            .bitcoin,
            .plain(" you’re not going to touch 🔒")
        ]),
        WelcomeLine(id: 7, segments: [
            .plain("for your home 🏡. a year off ✈️. something for the kids 🎓.")
        ]),
        WelcomeLine(id: 8, segments: [
            .plain("sats keeper is safe, no seed phrase, no account, just your address 🔐")
        ])
    ]
}
