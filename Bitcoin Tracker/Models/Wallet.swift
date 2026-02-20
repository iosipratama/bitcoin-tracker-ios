import Foundation
import SwiftData

@Model
final class Wallet {
    var name: String
    @Relationship(deleteRule: .cascade)
    var addresses: [BitcoinAddress]
    var createdAt: Date

    init(name: String) {
        self.name = name
        self.addresses = []
        self.createdAt = .now
    }

    var totalSatoshis: Int64 {
        addresses.reduce(0) { $0 + $1.balanceSatoshis }
    }

    var totalBTC: Double {
        Double(totalSatoshis) / 100_000_000
    }
}
