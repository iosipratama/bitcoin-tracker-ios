import Foundation
import Observation

/// Holds the wallet a widget asked for until `HomeView` is on screen to show it.
///
/// A launch from the Home Screen arrives before the wallet list has resolved,
/// so the id has to wait somewhere. Cleared once it has been used, so returning
/// to the app later doesn't push the same wallet again.
@Observable
@MainActor
final class WidgetRouter {
    private(set) var requestedWalletID: UUID?

    func open(_ url: URL) {
        guard let id = WalletLink.walletID(from: url) else { return }
        requestedWalletID = id
    }

    func clear() { requestedWalletID = nil }
}
