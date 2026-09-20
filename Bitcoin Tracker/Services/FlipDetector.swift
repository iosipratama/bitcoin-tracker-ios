import CoreMotion

/// Reports each time the device is turned face down. The only file that
/// touches CoreMotion, the way `StoreManager` is the only file that touches
/// StoreKit.
///
/// Reads gravity rather than asking UIKit for its orientation: on a real phone
/// `UIDevice` never reported `.faceDown` for this app, while the gravity vector
/// did exactly what the documentation says.
@MainActor
final class FlipDetector {
    /// Gravity along the device's z axis, which points out of the screen: face
    /// down reads near +1, face up near -1. The two thresholds are deliberately
    /// apart — one value would flicker whenever a phone came to rest near it.
    private static let facingDown = 0.8
    private static let facingUp = 0.5

    /// Ten times a second. Fast enough that the flip feels like the cause of the
    /// change rather than something that happened afterwards.
    private static let updateInterval = 0.1

    /// Fires once per flip, on the way down only. Turning the phone back over
    /// is deliberately not an event — a balance that uncovered itself the
    /// moment you picked the phone up would never have been covered at all.
    var onFlip: (() -> Void)?

    #if DEBUG
    /// Every sample, for the debug screen.
    var onSample: ((Double, Bool) -> Void)?
    #endif

    private let motion = CMMotionManager()
    private var isFaceDown = false
    private var isSeeded = false

    var isMonitoring: Bool { motion.isDeviceMotionActive }

    func start() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }

        isSeeded = false
        motion.deviceMotionUpdateInterval = Self.updateInterval
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.apply(gravityZ: data.gravity.z)
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }

    private func apply(gravityZ: Double) {
        // The first sample only establishes where the phone already is. A phone
        // that was face down before we started listening was never showing
        // anything to cover.
        guard isSeeded else {
            isFaceDown = gravityZ > Self.facingDown
            isSeeded = true
            report(gravityZ)
            return
        }

        if gravityZ > Self.facingDown, !isFaceDown {
            isFaceDown = true
            onFlip?()
        } else if gravityZ < Self.facingUp, isFaceDown {
            isFaceDown = false
        }

        report(gravityZ)
    }

    private func report(_ gravityZ: Double) {
        #if DEBUG
        onSample?(gravityZ, isFaceDown)
        #endif
    }
}
