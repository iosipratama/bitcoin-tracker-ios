import AppIntents
import Foundation

/// A wallet as the widget configuration sheet knows it: a name and the id the
/// choice is stored under.
///
/// `nonisolated` throughout — App Intents calls into these off the main actor,
/// and the target otherwise defaults to main-actor isolation.
nonisolated struct WalletEntity: AppEntity {
    var id: UUID
    var name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wallet" }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = WalletEntityQuery()

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    init(_ wallet: WalletSnapshot) {
        self.init(id: wallet.id, name: wallet.name)
    }
}

/// Answers from the snapshot the app writes. The widget has no other way to
/// know what wallets exist — it never opens the store.
nonisolated struct WalletEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [WalletEntity] {
        let wallets = PortfolioSnapshot.load()?.wallets ?? []
        // Ordered by the identifiers asked for, not by the snapshot, which is
        // what the framework expects back.
        return identifiers.compactMap { id in
            wallets.first { $0.id == id }.map(WalletEntity.init)
        }
    }

    func suggestedEntities() async throws -> [WalletEntity] {
        (PortfolioSnapshot.load()?.wallets ?? []).map(WalletEntity.init)
    }

    /// The first wallet, so a freshly placed widget shows a real balance
    /// instead of waiting to be configured.
    func defaultResult() async -> WalletEntity? {
        try? await suggestedEntities().first
    }
}
