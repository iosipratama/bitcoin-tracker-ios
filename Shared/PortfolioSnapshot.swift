import Foundation

/// What the app hands the widget: the wallets, and the settings that decide how
/// their figures are written.
///
/// A file rather than the shared SwiftData store. The store has shipped, it
/// holds people's wallets, and moving it into the app group would mean
/// migrating it out from under them — a risk with no upside here, since a
/// widget only ever reads. This also keeps `@Model` and SwiftData itself out of
/// the extension entirely.
///
/// The preferences ride along for the same reason: mirroring them here means
/// the app can go on writing to `UserDefaults.standard` exactly as it always
/// has, with nothing to migrate.
nonisolated struct PortfolioSnapshot: Codable, Sendable {
    var wallets: [WalletSnapshot]
    var currency: FiatCurrency
    var showSatoshi: Bool
    var showFiat: Bool

    /// One BTC in `currency` at the time of writing. Zero when unknown — the
    /// widget refetches anyway, and this is only the floor it falls back to.
    var price: Double
    var updatedAt: Date

    /// The formatter the app was using when this was written.
    var formatter: BalanceFormatter {
        BalanceFormatter(
            currency: currency,
            showSatoshi: showSatoshi,
            showFiat: showFiat,
            price: price
        )
    }

    func wallet(id: UUID?) -> WalletSnapshot? {
        guard let id else { return wallets.first }
        return wallets.first { $0.id == id } ?? wallets.first
    }

    static func load() -> PortfolioSnapshot? {
        guard let url = AppGroup.snapshotURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PortfolioSnapshot.self, from: data)
    }

    /// Atomic, so a widget reading mid-write sees the previous snapshot rather
    /// than half of this one.
    func save() {
        guard let url = AppGroup.snapshotURL,
              let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

/// One wallet, flattened. Mirrors the derived properties on `Wallet` so the
/// widget computes a balance and a goal the same way the app does.
nonisolated struct WalletSnapshot: Codable, Sendable, Identifiable {
    var id: UUID
    var name: String
    var symbol: WalletSymbol
    var accent: WalletAccent

    /// Carried so the widget can refetch on its own rather than waiting for the
    /// app to be opened.
    var addresses: [String]

    var balanceSatoshis: Int64
    var pendingSatoshis: Int64
    var goalSatoshis: Int64?
    var lastUpdated: Date?

    var balance: AddressBalance {
        AddressBalance(confirmedSatoshis: balanceSatoshis, pendingSatoshis: pendingSatoshis)
    }

    var totalSatoshis: Int64 { balance.totalSatoshis }
    var totalBTC: Double { balance.totalBTC }

    var hasGoal: Bool { (goalSatoshis ?? 0) > 0 }

    /// Unclamped, like `Wallet.goalProgress` — a wallet past its target reads
    /// 140% rather than stalling at 100%.
    var goalProgress: Double? {
        guard hasGoal, let goalSatoshis else { return nil }
        return Double(totalSatoshis) / Double(goalSatoshis)
    }

    /// The same wallet with fresher figures, leaving everything else alone.
    func applying(_ balance: AddressBalance) -> WalletSnapshot {
        var copy = self
        copy.balanceSatoshis = balance.confirmedSatoshis
        copy.pendingSatoshis = balance.pendingSatoshis
        copy.lastUpdated = .now
        return copy
    }
}
