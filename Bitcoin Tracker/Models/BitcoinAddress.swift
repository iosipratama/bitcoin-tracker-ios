import Foundation
import SwiftData

@Model
final class BitcoinAddress {
    var address: String

    /// Confirmed on-chain balance. Kept under its original name so existing
    /// stores migrate without a mapping model.
    var balanceSatoshis: Int64

    /// Unconfirmed mempool delta. Negative while an outgoing spend is pending.
    /// Defaults to zero so lightweight migration can add it.
    var pendingSatoshis: Int64 = 0

    var lastUpdated: Date?
    var fetchError: String?

    var wallet: Wallet?

    init(address: String) {
        self.address = address
        self.balanceSatoshis = 0
        self.pendingSatoshis = 0
        self.lastUpdated = nil
        self.fetchError = nil
    }

    var balance: AddressBalance {
        AddressBalance(confirmedSatoshis: balanceSatoshis, pendingSatoshis: pendingSatoshis)
    }

    var totalSatoshis: Int64 { balance.totalSatoshis }

    var balanceBTC: Double {
        Double(balanceSatoshis) / .satoshisPerBTC
    }

    func apply(_ balance: AddressBalance) {
        balanceSatoshis = balance.confirmedSatoshis
        pendingSatoshis = balance.pendingSatoshis
        lastUpdated = .now
        fetchError = nil
    }

    var shortAddress: String {
        guard address.count > 12 else { return address }
        let prefix = address.prefix(6)
        let suffix = address.suffix(6)
        return "\(prefix)...\(suffix)"
    }
}

// MARK: - Format validation

extension BitcoinAddress {
    /// Structural checks only — length and character set. A malformed address that
    /// passes here is still rejected by Blockstream when its balance is fetched.
    static func isValidFormat(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return isValidBech32(trimmed) || isValidBase58(trimmed)
    }

    /// Bech32/bech32m (P2WPKH, P2WSH, P2TR). Must be all one case; the data part
    /// excludes "1", "b", "i" and "o" so they can't be confused with 0/8.
    private static func isValidBech32(_ address: String) -> Bool {
        let lowered = address.lowercased()
        guard lowered.hasPrefix("bc1"), (14...74).contains(address.count) else { return false }
        guard address == lowered || address == address.uppercased() else { return false }

        let dataPart = lowered.dropFirst(3)
        let charset = Set("qpzry9x8gf2tvdw0s3jn54khce6mua7l")
        return !dataPart.isEmpty && dataPart.allSatisfy { charset.contains($0) }
    }

    /// Base58Check (P2PKH "1…", P2SH "3…"). The alphabet drops 0, O, I and l.
    private static func isValidBase58(_ address: String) -> Bool {
        guard address.hasPrefix("1") || address.hasPrefix("3") else { return false }
        guard (26...35).contains(address.count) else { return false }

        let charset = Set("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
        return address.allSatisfy { charset.contains($0) }
    }
}
