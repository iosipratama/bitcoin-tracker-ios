import UIKit

/// Reports each time the device is turned face down.
///
/// Asks UIKit for its own face-down classification rather than reading gravity
/// off the accelerometer: there is no threshold to tune, no axis sign to get
/// wrong, and nothing samples while the phone sits still.
@MainActor
final class FlipDetector {
    /// Fires once per flip, on the way down only. Turning the phone back over
    /// is deliberately not an event — a balance that uncovered itself the
    /// moment you picked the phone up would never have been covered at all.
    var onFlip: (() -> Void)?

    #if DEBUG
    /// Every orientation the device reports, including the ones that don't move
    /// the needle. Only the debug screen reads this.
    var onOrientation: ((UIDeviceOrientation) -> Void)?
    #endif

    private var observer: (any NSObjectProtocol)?
    private var isFaceDown = false

    var isMonitoring: Bool { observer != nil }

    func start() {
        guard observer == nil else { return }

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        // Seeded without reporting: a phone that was already face down was
        // never showing anything to cover.
        isFaceDown = UIDevice.current.orientation == .faceDown

        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.readOrientation()
            }
        }
    }

    func stop() {
        guard let observer else { return }

        NotificationCenter.default.removeObserver(observer)
        self.observer = nil
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    private func readOrientation() {
        let orientation = UIDevice.current.orientation

        #if DEBUG
        onOrientation?(orientation)
        #endif

        let faceDown = orientation == .faceDown
        guard faceDown != isFaceDown else { return }

        isFaceDown = faceDown
        if faceDown { onFlip?() }
    }
}

#if DEBUG
extension UIDeviceOrientation {
    /// For the debug readout, since the raw value is an integer.
    var name: String {
        switch self {
        case .portrait: "portrait"
        case .portraitUpsideDown: "upside down"
        case .landscapeLeft: "landscape left"
        case .landscapeRight: "landscape right"
        case .faceUp: "face up"
        case .faceDown: "face down"
        default: "unknown"
        }
    }
}
#endif
