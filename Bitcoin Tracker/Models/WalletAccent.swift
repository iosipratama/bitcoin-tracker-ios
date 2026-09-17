import SwiftUI

/// The colour of a wallet's symbol tile. Raw values are persisted by SwiftData,
/// so cases may be added but never renamed.
enum WalletAccent: String, CaseIterable, Codable, Identifiable {
    case green, pink, blue, purple, teal, orange, red, yellow

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .green: .walletGreen
        case .pink: .walletPink
        case .blue: .walletBlue
        case .purple: .walletPurple
        case .teal: .walletTeal
        case .orange: .walletOrange
        case .red: .walletRed
        case .yellow: .walletYellow
        }
    }
}
