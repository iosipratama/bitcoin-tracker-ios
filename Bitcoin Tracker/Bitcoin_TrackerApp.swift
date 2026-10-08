import SwiftUI
import SwiftData

@main
struct Bitcoin_TrackerApp: App {
    @State private var viewModel = PortfolioViewModel()
    @State private var store = StoreManager()
    @State private var router = WidgetRouter()
    @State private var lock = AppLock()
    @State private var activity = ActivityStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .environment(store)
                .environment(router)
                .environment(lock)
                .environment(activity)
                .task { await store.load() }
                .preferredColorScheme(viewModel.theme.colorScheme)
        }
        .modelContainer(Self.modelContainer)
    }

    /// Synced to the user's private iCloud database, so wallets come back after
    /// a reinstall or on a new iPhone. Signed out of iCloud, it still works as a
    /// local store and syncs once they sign in.
    private static let modelContainer: ModelContainer = {
        let schema = Schema([Wallet.self, BitcoinAddress.self])

        #if DEBUG
        // Screenshot mode's demo wallets must never reach the real iCloud
        // account, and a fresh store each launch keeps every capture identical.
        if ScreenshotScene.current != nil {
            let scratch = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return try! ModelContainer(for: schema, configurations: scratch)
        }
        #endif
        let synced = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private(CloudSyncMonitor.containerID)
        )
        _ = CloudSyncMonitor.shared
        do {
            return try ModelContainer(for: schema, configurations: synced)
        } catch {
            CloudSyncMonitor.shared.setupFailure = String(describing: error)
        }

        // Losing sync is better than failing to open someone's wallets at all.
        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        return try! ModelContainer(for: schema, configurations: local)
    }()
}
