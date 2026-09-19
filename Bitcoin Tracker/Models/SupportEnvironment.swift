import Foundation

/// The details a support reply would otherwise have to open by asking for them.
enum SupportEnvironment {
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// The raw identifier — `iPhone17,2` rather than "iPhone 16 Pro". A table of
    /// marketing names goes stale every September; this never does.
    static var deviceModel: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }

        var system = utsname()
        uname(&system)
        return withUnsafeBytes(of: &system.machine) { raw in
            guard let base = raw.baseAddress else { return "unknown" }
            return String(cString: base.assumingMemoryBound(to: CChar.self))
        }
    }

    /// Read from `ProcessInfo` rather than `UIDevice`, which is main-actor
    /// isolated and would drag this off any background caller.
    static var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion)"
    }

    /// Signed off at the end of a support mail, below a rule, so it reads as a
    /// footer rather than something the sender has to write around.
    static var mailSignature: String {
        """


        —
        Sats Keeper \(appVersion) (\(build))
        \(deviceModel) · iOS \(systemVersion)
        """
    }
}
