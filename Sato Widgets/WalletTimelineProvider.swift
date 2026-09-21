import AppIntents
import Foundation
import WidgetKit

nonisolated struct WalletEntry: TimelineEntry {
    var date: Date

    /// nil when there is nothing to show yet — no snapshot, or no wallets in it.
    var wallet: WalletSnapshot?
    var formatter: BalanceFormatter

    /// The refresh reached nothing and these figures came from the snapshot.
    /// Not surfaced as an error: a stale balance is still a true one, and the
    /// app makes the same choice.
    var isStale: Bool = false
}

/// Shared by both widgets, because both need exactly the same thing: one
/// wallet, refreshed.
///
/// The widget fetches for itself rather than waiting on the app. A tracker you
/// can go a month without opening is the point of this app, and a Home Screen
/// figure a month old would quietly undo that.
nonisolated struct WalletTimelineProvider: AppIntentTimelineProvider {

    /// Roughly hourly. Calm enough to suit the app, and well inside the budget
    /// WidgetKit allows before it starts ignoring the request.
    private static let refreshInterval: TimeInterval = 60 * 60

    /// The same ceiling `PortfolioViewModel` uses. Public explorers throttle
    /// aggressive clients, and a throttled widget shows a stale figure.
    private static let maxConcurrentFetches = 4

    func placeholder(in context: Context) -> WalletEntry {
        .sample
    }

    func snapshot(for configuration: SelectWalletIntent, in context: Context) async -> WalletEntry {
        // The widget gallery renders many of these at once, so it gets the
        // stored figures and no network at all.
        guard !context.isPreview else { return .sample }
        return stored(for: configuration) ?? .sample
    }

    func timeline(for configuration: SelectWalletIntent, in context: Context) async -> Timeline<WalletEntry> {
        let entry = await refreshed(for: configuration)
        return Timeline(entries: [entry], policy: .after(.now + Self.refreshInterval))
    }

    // MARK: - Entries

    private func stored(for configuration: SelectWalletIntent) -> WalletEntry? {
        guard let snapshot = PortfolioSnapshot.load() else { return nil }
        return WalletEntry(
            date: .now,
            wallet: snapshot.wallet(id: configuration.wallet?.id),
            formatter: snapshot.formatter
        )
    }

    private func refreshed(for configuration: SelectWalletIntent) async -> WalletEntry {
        guard let snapshot = PortfolioSnapshot.load(),
              let wallet = snapshot.wallet(id: configuration.wallet?.id) else {
            return WalletEntry(date: .now, wallet: nil, formatter: .placeholder)
        }

        var formatter = snapshot.formatter
        if let price = try? await PriceService.shared.price(for: snapshot.currency) {
            formatter.price = price
        }

        let balances = await Self.fetchBalances(for: wallet.addresses)

        // Every address has to answer before the total means anything — one
        // missing reply would read as coins having left the wallet.
        guard balances.count == wallet.addresses.count else {
            return WalletEntry(date: .now, wallet: wallet, formatter: formatter, isStale: true)
        }

        let total = balances.values.reduce(AddressBalance.zero) { running, balance in
            AddressBalance(
                confirmedSatoshis: running.confirmedSatoshis + balance.confirmedSatoshis,
                pendingSatoshis: running.pendingSatoshis + balance.pendingSatoshis
            )
        }

        return WalletEntry(date: .now, wallet: wallet.applying(total), formatter: formatter)
    }

    /// Only the addresses that answered. A failure is left out rather than
    /// counted as zero.
    private static func fetchBalances(for addresses: [String]) async -> [String: AddressBalance] {
        let unique = Array(Set(addresses))
        guard !unique.isEmpty else { return [:] }

        return await withTaskGroup(of: (String, AddressBalance?).self) { group in
            var results: [String: AddressBalance] = [:]
            var next = 0

            func enqueue() {
                guard next < unique.count else { return }
                let address = unique[next]
                next += 1
                group.addTask {
                    (address, try? await BitcoinAPIService.shared.fetchBalance(for: address))
                }
            }

            for _ in 0..<min(maxConcurrentFetches, unique.count) { enqueue() }

            while let (address, balance) = await group.next() {
                if let balance { results[address] = balance }
                enqueue()
            }

            return results
        }
    }
}

nonisolated extension BalanceFormatter {
    /// Stands in before any snapshot exists, when there is no balance to format
    /// anyway.
    static let placeholder = BalanceFormatter(currency: .usd, showSatoshi: false, showFiat: true)
}

nonisolated extension WalletEntry {
    /// What the widget gallery shows. Deliberately a plausible stack rather
    /// than a round number, so the layout is judged at the width it will
    /// actually have to hold.
    static let sample = WalletEntry(
        date: .now,
        wallet: WalletSnapshot(
            id: UUID(),
            name: "Retirement",
            symbol: .holiday,
            accent: .orange,
            addresses: [],
            balanceSatoshis: 1_203_400,
            pendingSatoshis: 0,
            goalSatoshis: 100_000_000,
            lastUpdated: .now
        ),
        formatter: BalanceFormatter(
            currency: .usd,
            showSatoshi: false,
            showFiat: true,
            price: 87_000
        )
    )
}
