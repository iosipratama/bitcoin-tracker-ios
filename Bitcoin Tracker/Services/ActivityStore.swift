import Foundation
import Observation

/// Recent Activity for each wallet, kept on the device so the list is there the
/// moment a wallet opens — even on a slow network or none — and replaced only
/// when a refresh brings back something new.
///
/// A file rather than SwiftData: the history can always be fetched again, so
/// it has no business in the user's iCloud, and leaving the synced models alone
/// spares a CloudKit schema change.
@Observable
@MainActor
final class ActivityStore {
    static let limit = 10

    /// Within this, opening a wallet again shows what's stored and asks nothing
    /// of the network — unless the balance moved, which means there is news.
    private static let freshness: Duration = .seconds(120)

    private static let maxConcurrentFetches = 4

    private(set) var entries: [String: Entry] = [:]
    private(set) var loadingKeys: Set<String> = []
    private(set) var failedKeys: Set<String> = []

    private let fileURL: URL

    init() {
        let directory = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Versioned so a list stored without counterparties is fetched again
        // rather than shown with its "from" lines missing.
        fileURL = directory.appending(path: "RecentActivity-2.json")

        if let data = try? Data(contentsOf: fileURL),
           let stored = try? JSONDecoder().decode([String: Entry].self, from: data) {
            entries = stored
        }
    }

    /// Keyed by the address set rather than the wallet, so adding or removing an
    /// address starts a fresh history instead of showing one that no longer
    /// adds up.
    static func key(for wallet: Wallet) -> String {
        wallet.addressList.map(\.address).sorted().joined(separator: ",")
    }

    func entry(for wallet: Wallet) -> Entry? { entries[Self.key(for: wallet)] }
    func isLoading(_ wallet: Wallet) -> Bool { loadingKeys.contains(Self.key(for: wallet)) }
    func didFail(_ wallet: Wallet) -> Bool { failedKeys.contains(Self.key(for: wallet)) }

    func refresh(_ wallet: Wallet, force: Bool = false) async {
        let key = Self.key(for: wallet)
        let addresses = wallet.addressList.map(\.address)
        let balance = wallet.totalSatoshis

        guard !addresses.isEmpty, !loadingKeys.contains(key) else { return }

        #if DEBUG
        if ScreenshotScene.freezesBalances, entries[key] != nil { return }
        #endif

        if !force, let entry = entries[key], entry.balanceSatoshis == balance,
           entry.updated.addingTimeInterval(Self.freshness.seconds) > .now {
            return
        }

        loadingKeys.insert(key)
        defer { loadingKeys.remove(key) }

        do {
            let items = try await Self.fetch(addresses)
            failedKeys.remove(key)
            entries[key] = Entry(items: items, updated: .now, balanceSatoshis: balance)
            save()
        } catch {
            // What's stored stays on screen; a partial list would be worse than
            // a slightly old one.
            failedKeys.insert(key)
        }
    }

    #if DEBUG
    /// Screenshot mode's history, marked fresh so opening the wallet doesn't
    /// replace it with the network's.
    func seed(_ wallet: Wallet, items: [ActivityItem]) {
        entries[Self.key(for: wallet)] = Entry(
            items: items.sorted(by: ActivityItem.newestFirst),
            updated: .now.addingTimeInterval(3600),
            balanceSatoshis: wallet.totalSatoshis
        )
        // Kept across launches for the Debug screen's demo balances; screenshot
        // mode's store is in memory, so there it simply isn't read back.
        if ScreenshotScene.current == nil { save() }
    }
    #endif

    private nonisolated static func fetch(_ addresses: [String]) async throws -> [ActivityItem] {
        var transactions: [String: EsploraTransaction] = [:]

        for batch in stride(from: 0, to: addresses.count, by: maxConcurrentFetches) {
            let slice = addresses[batch..<min(batch + maxConcurrentFetches, addresses.count)]
            try await withThrowingTaskGroup(of: [EsploraTransaction].self) { group in
                for address in slice {
                    group.addTask { try await BitcoinAPIService.shared.fetchTransactions(for: address) }
                }
                for try await page in group {
                    for transaction in page { transactions[transaction.txid] = transaction }
                }
            }
        }

        let owned = Set(addresses)
        let items = transactions.values.compactMap { transaction -> ActivityItem? in
            let net = transaction.netSatoshis(for: owned)
            guard net != 0 else { return nil }
            return ActivityItem(
                id: transaction.txid,
                netSatoshis: net,
                date: transaction.status.block_time.map(Date.init(timeIntervalSince1970:)),
                counterparty: transaction.counterparty(for: owned, isReceived: net > 0)
            )
        }

        return Array(items.sorted(by: ActivityItem.newestFirst).prefix(limit))
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

extension ActivityStore {
    struct Entry: Codable, Sendable {
        var items: [ActivityItem]
        var updated: Date
        /// The wallet's balance when this was fetched. A different balance now
        /// means a transaction this list hasn't seen.
        var balanceSatoshis: Int64
    }
}

/// One transaction as it touched a wallet: in or out, how much, and when.
nonisolated struct ActivityItem: Codable, Sendable, Identifiable, Hashable {
    /// The transaction ID.
    var id: String
    var netSatoshis: Int64
    /// The block's timestamp. nil while the transaction is still pending.
    var date: Date?
    /// Who sent it or where it went. Optional so lists stored before it existed
    /// still decode.
    var counterparty: String?

    var isReceived: Bool { netSatoshis > 0 }
    var isPending: Bool { date == nil }

    /// What the second line says: who it came from or went to.
    var counterpartyLine: String {
        guard let counterparty else { return isReceived ? "Newly mined" : "Between your addresses" }
        return "\(isReceived ? "from" : "to") \(BitcoinAddress.shortened(counterparty))"
    }


    /// Pending first, since it's the newest thing that's happened.
    static func newestFirst(_ lhs: ActivityItem, _ rhs: ActivityItem) -> Bool {
        switch (lhs.date, rhs.date) {
        case (nil, nil): lhs.id < rhs.id
        case (nil, _): true
        case (_, nil): false
        case let (left?, right?): left > right
        }
    }
}

private extension Duration {
    var seconds: TimeInterval { TimeInterval(components.seconds) }
}
