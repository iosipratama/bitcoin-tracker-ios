import Foundation

/// The URL a widget hands back to the app when it's tapped: `sato://wallet/<id>`.
///
/// Both ends of that trip are in this file, because a link that is written in
/// one target and read in another is exactly the kind of string that drifts.
nonisolated enum WalletLink {
    static let scheme = "sato"

    static func url(walletID: UUID) -> URL? {
        URL(string: "\(scheme)://wallet/\(walletID.uuidString)")
    }

    static func walletID(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host() == "wallet" else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
