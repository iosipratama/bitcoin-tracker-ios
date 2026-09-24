import LocalAuthentication
import SwiftUI

/// Face ID on launch and on return, and a cover over the app switcher's
/// snapshot. Both are off by default.
@Observable
@MainActor
final class AppLock {
    private enum Key {
        static let requiresAuthentication = "requiresAuthentication"
        static let hidesInAppSwitcher = "hidesInAppSwitcher"
    }

    private(set) var requiresAuthentication: Bool {
        didSet { UserDefaults.standard.set(requiresAuthentication, forKey: Key.requiresAuthentication) }
    }

    var hidesInAppSwitcher: Bool {
        didSet { UserDefaults.standard.set(hidesInAppSwitcher, forKey: Key.hidesInAppSwitcher) }
    }

    private(set) var isLocked: Bool
    private(set) var isInactive = false
    private var isAuthenticating = false

    /// Only a return from the background prompts on its own. The prompt itself
    /// makes the scene inactive and then active again, so prompting on every
    /// `.active` would bring a cancelled prompt straight back.
    private var promptsOnActive: Bool

    var coversScreen: Bool { isLocked || (isInactive && hidesInAppSwitcher) }

    /// False when the device has neither biometrics nor a passcode.
    var canAuthenticate: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    /// Named for the hardware in hand, so a Touch ID iPhone doesn't offer Face ID.
    var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return switch context.biometryType {
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        default: "Face ID"
        }
    }

    init() {
        let defaults = UserDefaults.standard
        let requires = defaults.bool(forKey: Key.requiresAuthentication)
        requiresAuthentication = requires
        hidesInAppSwitcher = defaults.bool(forKey: Key.hidesInAppSwitcher)
        isLocked = requires
        promptsOnActive = requires
    }

    func sceneDidChange(to phase: ScenePhase) {
        isInactive = phase != .active

        switch phase {
        case .background:
            if requiresAuthentication {
                isLocked = true
                promptsOnActive = true
            }
        case .active:
            if isLocked && promptsOnActive {
                promptsOnActive = false
                Task { await unlock() }
            }
        default:
            break
        }
    }

    func unlock() async {
        guard isLocked else { return }
        if await authenticate(reason: "Unlock Sato to see your wallets.") {
            isLocked = false
        }
    }

    /// Switching the lock on asks first, so nobody finds out on the next launch
    /// that their device can't pass it.
    func setRequiresAuthentication(_ requires: Bool) async {
        guard requires != requiresAuthentication else { return }
        if requires {
            guard await authenticate(reason: "Confirm it's you to lock Sato.") else { return }
        }
        requiresAuthentication = requires
    }

    private func authenticate(reason: String) async -> Bool {
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            return try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
