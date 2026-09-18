import SwiftUI

/// The colour of a wallet's symbol tile.
///
/// The system palette rather than a custom one: these read correctly on dark
/// backgrounds, already adapt to accessibility settings, and are the set people
/// recognise from Apple's own apps.
///
/// Raw values are persisted by SwiftData, so cases may be added but never
/// renamed.
enum WalletAccent: String, CaseIterable, Codable, Identifiable {
    case red, orange, yellow, green, cyan, blue
    case indigo, pink, purple, teal, brown, mint

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .cyan: .cyan
        case .blue: .blue
        case .indigo: .indigo
        case .pink: .pink
        case .purple: .purple
        case .teal: .teal
        case .brown: .brown
        case .mint: .mint
        }
    }
}
