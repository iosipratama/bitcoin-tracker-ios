import Foundation

/// The symbol on a wallet's tile.
///
/// Cases are named for what they mean rather than for the SF Symbol behind them,
/// so the artwork can be swapped without invalidating anything already stored.
/// Raw values are persisted by SwiftData; add cases freely, never rename them.
enum WalletSymbol: String, CaseIterable, Codable, Identifiable {
    case bitcoin, family, heart, home, vault, gift
    case education, star, leaf, shield, travel, savings

    var id: String { rawValue }

    var systemName: String {
        switch self {
        case .bitcoin: "bitcoinsign"
        case .family: "figure.2.and.child.holdinghands"
        case .heart: "heart.fill"
        case .home: "house.fill"
        case .vault: "lock.fill"
        case .gift: "gift.fill"
        case .education: "graduationcap.fill"
        case .star: "star.fill"
        case .leaf: "leaf.fill"
        case .shield: "shield.fill"
        case .travel: "airplane"
        case .savings: "banknote.fill"
        }
    }
}
