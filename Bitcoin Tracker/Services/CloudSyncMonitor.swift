import CloudKit
import CoreData
import Observation

/// What iCloud sync is actually doing. Sync fails silently by design — the
/// store keeps working locally — so this is the only way to see why wallets
/// aren't arriving on another install.
@Observable
@MainActor
final class CloudSyncMonitor {
    static let shared = CloudSyncMonitor()
    static let containerID = "iCloud.com.iosipratama.BitcoinTracker"

    /// Set when the synced store couldn't open and the app fell back to a
    /// local-only one.
    var setupFailure: String?
    var accountStatus = "Checking…"
    var lastSetup = "None yet"
    var lastImport = "None yet"
    var lastExport = "None yet"

    private var observer: NSObjectProtocol?

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event,
                event.endDate != nil
            else { return }

            let summary = Self.describe(event)
            let type = event.type
            MainActor.assumeIsolated {
                switch type {
                case .setup: CloudSyncMonitor.shared.lastSetup = summary
                case .import: CloudSyncMonitor.shared.lastImport = summary
                case .export: CloudSyncMonitor.shared.lastExport = summary
                @unknown default: break
                }
            }
        }
    }

    func refreshAccountStatus() async {
        do {
            let status = try await CKContainer(identifier: Self.containerID).accountStatus()
            accountStatus = switch status {
            case .available: "Signed in"
            case .noAccount: "Not signed in to iCloud"
            case .restricted: "Restricted"
            case .couldNotDetermine: "Couldn't determine"
            case .temporarilyUnavailable: "Temporarily unavailable"
            @unknown default: "Unknown"
            }
        } catch {
            accountStatus = error.localizedDescription
        }
    }

    private nonisolated static func describe(_ event: NSPersistentCloudKitContainer.Event) -> String {
        let time = (event.endDate ?? .now).formatted(date: .omitted, time: .standard)
        if event.succeeded { return "OK at \(time)" }
        return "Failed at \(time): \(event.error?.localizedDescription ?? "no error given")"
    }
}
