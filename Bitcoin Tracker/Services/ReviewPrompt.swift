import Foundation

/// Decides whether the app has earned the right to ask for a review.
///
/// iOS allows three prompts per year and silently swallows the rest, so the
/// cost of asking at a weak moment isn't a declined dialog — it's one of three
/// chances spent on someone who has no opinion yet. Hence the guards.
enum ReviewPrompt {
    private enum Key {
        static let hasAsked = "hasAskedForReview"
    }

    /// Long enough for the sheet to finish dismissing and the new card to
    /// settle, so the dialog lands on a screen that has stopped moving.
    static let delay: Duration = .seconds(2)

    static var hasAsked: Bool {
        UserDefaults.standard.bool(forKey: Key.hasAsked)
    }

    static func markAsked() {
        UserDefaults.standard.set(true, forKey: Key.hasAsked)
    }

    #if DEBUG
    static func reset() {
        UserDefaults.standard.removeObject(forKey: Key.hasAsked)
    }
    #endif

    /// Only once the app has visibly done its job: a wallet exists and its
    /// balance came back. Asking on the bare act of adding one would be asking
    /// before there is anything to have an opinion about — and never ask on the
    /// back of a failed refresh, when the most recent thing the app did was
    /// fail.
    static func isEarned(wallets: [Wallet], refreshFailed: Bool) -> Bool {
        guard !hasAsked, !refreshFailed else { return false }

        guard let newest = wallets.max(by: { $0.createdAt < $1.createdAt }) else {
            return false
        }

        return newest.addresses.contains { $0.lastUpdated != nil && $0.fetchError == nil }
    }
}
