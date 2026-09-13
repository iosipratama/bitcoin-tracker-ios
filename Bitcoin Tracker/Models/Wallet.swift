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
