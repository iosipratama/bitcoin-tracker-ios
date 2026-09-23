import SwiftUI

/// The first thing a new user sees. Nine lines that set expectations before any
/// balance appears, then one way forward.
///
/// The lines arrive one at a time, at reading pace rather than on a metronome:
/// a longer line earns a longer pause before the next, and there is an extra
/// beat before the two lines where the argument turns. Each line lands in
/// monochrome and takes its colour as the next one appears; the button comes
/// last, like a full stop. A tap anywhere finishes the whole thing at once.
struct WelcomeView: View {
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var revealedCount = 0
    @State private var colouredCount = 0
    @State private var showsButton = false

    private var lines: [WelcomeLine] { WelcomeLine.all }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                    let isRevealed = index < revealedCount
                    let isStill = isRevealed || reduceMotion

                    line.text
                        .tracking(0.34)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .grayscale(index < colouredCount ? 0 : 1)
                        .blur(radius: isStill ? 0 : 6)
                        .offset(y: isStill ? 0 : 10)
                        .opacity(isRevealed ? 1 : 0)
                        .accessibilityLabel(line.spokenText)
                        .accessibilityHidden(!isRevealed)
                }
            }
            .font(.system(size: 20, weight: .light))
            .fontDesign(.rounded)
            .foregroundStyle(Custom.labelSecondary)
            .padding(.horizontal, 32)
            .padding(.top, 36)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .softScrollEdge(for: .bottom)
        .onTapGesture { finish() }
        .safeAreaInset(edge: .bottom) { continueButton }
        .background(Custom.backgroundBase)
        .sensoryFeedback(trigger: showsButton) { _, landed in
            landed ? .impact(weight: .light) : nil
        }
        .task { await reveal() }
    }

    private var continueButton: some View {
        ProminentCapsuleButton(title: "Continue", action: onContinue)
            .scaleEffect(showsButton || reduceMotion ? 1 : 0.96)
            .offset(y: showsButton || reduceMotion ? 0 : 12)
            .opacity(showsButton ? 1 : 0)
            .allowsHitTesting(showsButton)
            .padding(.bottom, 46)
    }

    // MARK: - Choreography

    private func reveal() async {
        // VoiceOver reads the page top to bottom on its own schedule; a reveal
        // racing it would only hide lines it is about to speak.
        guard !voiceOverEnabled else { return finish(animated: false) }

        for index in lines.indices {
            try? await Task.sleep(for: WelcomeLine.pause(before: index))
            guard !Task.isCancelled, !showsButton else { return }

            withAnimation(.smooth(duration: 0.55)) { revealedCount = index + 1 }
            withAnimation(.smooth(duration: 0.5)) { colouredCount = index }
        }

        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled, !showsButton else { return }
        withAnimation(.smooth(duration: 0.5)) { colouredCount = lines.count }

        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled, !showsButton else { return }
        withAnimation(.snappy(duration: 0.55)) { showsButton = true }
    }

    private func finish(animated: Bool = true) {
        guard !showsButton else { return }

        withAnimation(animated ? .smooth(duration: 0.3) : nil) {
            revealedCount = lines.count
            colouredCount = lines.count
            showsButton = true
        }
    }
}

// MARK: - Copy

/// One paragraph, kept as data so the wording stays readable and the view stays
/// free of a wall of `+` operators.
private struct WelcomeLine: Identifiable {
    let id: Int
    let segments: [WelcomeSegment]

    /// Marks a line the argument turns on, which earns a longer pause before it.
    var beatBefore = false

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

    /// The pause before a line is set by the length of the one before it, so
    /// the sequence keeps roughly the pace of someone reading along.
    static func pause(before index: Int) -> Duration {
        guard index > 0 else { return .milliseconds(250) }

        let dwell = 0.1 + 0.005 * Double(all[index - 1].spokenText.count)
        let beat = all[index].beatBefore ? 0.2 : 0
        return .seconds(dwell + beat)
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
        ], beatBefore: true),
        WelcomeLine(id: 5, segments: [
            .plain("and this app, sato.")
        ], beatBefore: true),
        WelcomeLine(id: 6, segments: [
            .plain("is for the "),
            .bitcoin,
            .plain(" you’re holding long-term 🌱")
        ]),
        WelcomeLine(id: 7, segments: [
            .plain("for your home 🏡. a year off ✈️. something for the kids 🎓.")
        ]),
        WelcomeLine(id: 8, segments: [
            .plain("sato is safe, no seed phrase, no account, just your address 🔐")
        ])
    ]
}
