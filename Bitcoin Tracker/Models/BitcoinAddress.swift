import Foundation
import SwiftData

@Model
final class BitcoinAddress {
    var address: String
    var balanceSatoshis: Int64
    var lastUpdated: Date?
    var fetchError: String?

    var wallet: Wallet?

    init(address: String) {
        self.address = address
        self.balanceSatoshis = 0
        self.lastUpdated = nil
        self.fetchError = nil
    }

    var balanceBTC: Double {
        Double(balanceSatoshis) / 100_000_000
    }

    var shortAddress: String {
        guard address.count > 12 else { return address }
        let prefix = address.prefix(6)
        let suffix = address.suffix(6)
        return "\(prefix)...\(suffix)"
    }
}
