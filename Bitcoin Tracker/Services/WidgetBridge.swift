import Foundation
import SwiftData
import WidgetKit

/// The app's one way of telling the Home Screen what it knows.
///
/// Everything a widget shows arrives through here, so there is a single place
/// to look when one is showing the wrong wallet, the wrong currency, or a
/// figure from yesterday.
@MainActor
enum WidgetBridge {

    /// Reads the wallets itself rather than taking a list, so a caller can't
    /// publish a filtered view by accident and quietly delete someone's widget.
    static func publish(context: ModelContext, formatter: BalanceFormatter) {
        let descriptor = FetchDescriptor<Wallet>(sortBy: [SortDescriptor(\.createdAt)])
        guard let wallets = try? context.fetch(descriptor) else { return }

        let snapshots = wallets.map { $0.snapshot() }

        // `snapshot()` mints a `widgetID` for any wallet that has never been on
        // the Home Screen. Unsaved, the widget's stored configuration would
        // point at an id the app forgets on relaunch, and every wallet would
        // look deleted.
        if context.hasChanges { try? context.save() }

        PortfolioSnapshot(
            wallets: snapshots,
            currency: formatter.currency,
            showSatoshi: formatter.showSatoshi,
            showFiat: formatter.showFiat,
            price: formatter.price,
            updatedAt: .now
        ).save()

        WidgetCenter.shared.reloadAllTimelines()
    }
}
