import Foundation

/// The one container the app and its widgets both reach into.
///
/// Derived from the app's bundle id, which is registered with App Store Connect
/// and can never change — so this string can't either.
///
/// `nonisolated` because both targets default to main-actor isolation, and the
/// explorer actor and the widget's timeline provider both reach in from off the
/// main actor.
nonisolated enum AppGroup {
    static let id = "group.com.iosipratama.BitcoinTracker"

    /// Falls back to `.standard` rather than trapping. A missing entitlement is
    /// a signing problem, and the app losing its preferences on top of that
    /// would only bury the real cause.
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
    }

    static var snapshotURL: URL? {
        containerURL?.appending(path: "PortfolioSnapshot.json")
    }
}
