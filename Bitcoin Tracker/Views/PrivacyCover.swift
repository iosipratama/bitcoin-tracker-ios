import SwiftUI
import UIKit

/// What sits over the app while it's locked or in the app switcher. Drawn in a
/// window of its own, above every sheet, alert and share sheet — a cover
/// applied inside SwiftUI stops at the first presented sheet.
struct PrivacyCover: View {
    @Environment(AppLock.self) private var lock

    var body: some View {
        ZStack {
            if lock.isLocked {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Image(.launchSymbol)
                        .accessibilityHidden(true)

                    Spacer()

                    ProminentCapsuleButton(title: "Unlock") {
                        Task { await lock.unlock() }
                    }
                    .padding(.bottom, 24)
                }
            } else {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .ignoresSafeArea()
            }
        }
        .fontDesign(.rounded)
    }
}

/// Shows and hides `PrivacyCover` in a window at alert level.
@MainActor
final class PrivacyWindow {
    static let shared = PrivacyWindow()

    private var window: UIWindow?

    func update(covering: Bool, lock: AppLock, colorScheme: ColorScheme?) {
        guard covering else {
            window?.isHidden = true
            return
        }

        if window == nil {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }

            let controller = UIHostingController(rootView: PrivacyCover().environment(lock))
            controller.view.backgroundColor = .clear

            let window = UIWindow(windowScene: scene)
            window.windowLevel = .alert + 1
            window.rootViewController = controller
            self.window = window
        }

        window?.overrideUserInterfaceStyle = switch colorScheme {
        case .light: .light
        case .dark: .dark
        default: .unspecified
        }
        window?.isHidden = false
    }
}
