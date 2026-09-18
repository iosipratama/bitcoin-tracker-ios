import Foundation
import SwiftData

@Model
final class Wallet {
    var name: String
    @Relationship(deleteRule: .cascade)
    var addresses: [BitcoinAddress]
    var createdAt: Date

    /// Stored as optional raw strings rather than as the enums themselves.
    /// Lightweight migration only fills a declared default for primitive
    /// attributes; a non-optional enum comes back nil on rows that predate it
    /// and traps on cast. Optional attributes are always safe to add.
    ///
    /// nil means "not chosen" — the tile is then derived from the name, so
    /// wallets created before this existed still look varied.
    private var symbolName: String?
    private var accentName: String?

    var symbol: WalletSymbol {
        get { symbolName.flatMap(WalletSymbol.init(rawValue:)) ?? Self.defaultSymbol(for: name) }
        set { symbolName = newValue.rawValue }
    }

    var accent: WalletAccent {
        get { accentName.flatMap(WalletAccent.init(rawValue:)) ?? Self.defaultAccent(for: name) }
        set { accentName = newValue.rawValue }
    }

    init(name: String) {
        self.name = name
        self.addresses = []
        self.createdAt = .now
    }

    var balance: AddressBalance {
        addresses.reduce(.zero) { running, address in
            AddressBalance(
                confirmedSatoshis: running.confirmedSatoshis + address.balanceSatoshis,
                pendingSatoshis: running.pendingSatoshis + address.pendingSatoshis
            )
        }
    }

    var totalSatoshis: Int64 { balance.totalSatoshis }

    var totalBTC: Double { balance.totalBTC }
}

// MARK: - Address lookup

extension Wallet {
    /// The wallet already tracking this address, if any. The same address in two
    /// wallets would be counted twice in every total, so it may only live in one.
    static func owner(of address: String, in wallets: [Wallet]) -> Wallet? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return wallets.first { wallet in
            wallet.addresses.contains {
                $0.address.caseInsensitiveCompare(trimmed) == .orderedSame
            }
        }
    }
}

// MARK: - Derived defaults

extension Wallet {
    static func defaultSymbol(for name: String) -> WalletSymbol {
        WalletSymbol.allCases[Int(name.stableHash % UInt64(WalletSymbol.allCases.count))]
    }

    static func defaultAccent(for name: String) -> WalletAccent {
        // A second, independent hash rather than shifted bits of the first:
        // shifting left symbol and accent visibly correlated on short names.
        WalletAccent.allCases[Int(name.stableHashAlt % UInt64(WalletAccent.allCases.count))]
    }
}

private extension String {
    /// djb2. Deliberately not `hashValue`, which Swift seeds randomly per
    /// process — a wallet would pick a different tile on every launch.
    var stableHash: UInt64 {
        unicodeScalars.reduce(UInt64(5381)) { ($0 &* 33) &+ UInt64($1.value) }
    }

    var stableHashAlt: UInt64 {
        unicodeScalars.reduce(UInt64(7919)) { ($0 &* 31) ^ UInt64($1.value) }
    }
}
