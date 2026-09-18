import Foundation

/// The symbol on a wallet's tile.
///
/// Cases are named for what they mean rather than for the SF Symbol behind them,
/// so the artwork can be swapped without invalidating anything already stored.
/// Raw values are persisted by SwiftData; add cases freely, never rename them.
enum WalletSymbol: String, CaseIterable, Codable, Identifiable {
    case family, parent, baby, heart, pet, holiday
    case health, growth, savings, card, star, home
    case car, tools, devices, education, work, travel
    case luggage, food, shopping, clothes, medical, fitness
    case gaming, gift, celebration, gratitude, night, energy

    var id: String { rawValue }

    var systemName: String {
        switch self {
        case .family: "figure.2.and.child.holdinghands"
        case .parent: "figure.and.child.holdinghands"
        case .baby: "stroller.fill"
        case .heart: "heart.circle.fill"
        case .pet: "pawprint.fill"
        case .holiday: "beach.umbrella.fill"
        case .health: "cross.case.fill"
        case .growth: "chart.line.uptrend.xyaxis"
        case .savings: "banknote.fill"
        case .card: "creditcard.fill"
        case .star: "star.fill"
        case .home: "house.fill"
        case .car: "car.fill"
        case .tools: "hammer.fill"
        case .devices: "laptopcomputer.and.iphone"
        case .education: "graduationcap.fill"
        case .work: "briefcase.fill"
        case .travel: "airplane"
        case .luggage: "suitcase.rolling.fill"
        case .food: "fork.knife"
        case .shopping: "bag.fill"
        case .clothes: "tshirt.fill"
        case .medical: "stethoscope"
        case .fitness: "dumbbell.fill"
        case .gaming: "gamecontroller.fill"
        case .gift: "gift.fill"
        case .celebration: "party.popper.fill"
        case .gratitude: "hands.and.sparkles.fill"
        case .night: "moon.stars.fill"
        case .energy: "bolt.fill"
        }
    }
}
