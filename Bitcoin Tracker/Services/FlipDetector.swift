import CoreMotion

/// Reports whether the device is lying face down. The only file that touches
/// CoreMotion, the way `StoreManager` is the only file that touches StoreKit.
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

    /// Called only when the answer changes, never on every sample.
    var onChange: ((Bool) -> Void)?

    private let motion = CMMotionManager()
    private var isFaceDown = false

    func start() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }

        motion.deviceMotionUpdateInterval = Self.updateInterval
        motion.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.apply(gravityZ: motion.gravity.z)
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        update(isFaceDown: false)
    }

    private func apply(gravityZ: Double) {
        if gravityZ > Self.facingDown {
            update(isFaceDown: true)
        } else if gravityZ < Self.facingUp {
            update(isFaceDown: false)
        }
    }

    private func update(isFaceDown: Bool) {
        guard isFaceDown != self.isFaceDown else { return }
        self.isFaceDown = isFaceDown
        onChange?(isFaceDown)
    }
}
