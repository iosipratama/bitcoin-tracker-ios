import Foundation

/// A point-in-time balance for a single address, split into what the chain has
/// confirmed and what is still sitting in the mempool.
struct AddressBalance: Sendable, Equatable {
    var confirmedSatoshis: Int64
    var pendingSatoshis: Int64

    static let zero = AddressBalance(confirmedSatoshis: 0, pendingSatoshis: 0)

    /// Pending can be negative when an outgoing spend is unconfirmed, so this is
    /// deliberately signed arithmetic rather than an unsigned sum.
    var totalSatoshis: Int64 { confirmedSatoshis + pendingSatoshis }

    var confirmedBTC: Double { Double(confirmedSatoshis) / .satoshisPerBTC }
    var pendingBTC: Double { Double(pendingSatoshis) / .satoshisPerBTC }
    var totalBTC: Double { Double(totalSatoshis) / .satoshisPerBTC }

    var hasPending: Bool { pendingSatoshis != 0 }
}

extension Double {
    static let satoshisPerBTC: Double = 100_000_000
}
