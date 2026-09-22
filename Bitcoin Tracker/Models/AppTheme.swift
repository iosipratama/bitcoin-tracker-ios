import SwiftUI

/// Which appearance the app draws in. Automatic follows the device, which is
/// the default: a wallet you check twice a week should look like the phone
/// around it, not insist on its own weather.
///
/// Raw values are persisted, so cases may be added but never renamed.
enum AppTheme: String, CaseIterable, Identifiable {
    case automatic, light, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// nil means "don't override", which is what `preferredColorScheme` takes
    /// to mean "follow the system".
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
