import SwiftUI
import SwiftData

@main
struct Bitcoin_TrackerApp: App {
    @State private var viewModel = PortfolioViewModel()
    @State private var store = StoreManager()
    @State private var router = WidgetRouter()
    @State private var lock = AppLock()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .environment(store)
                .environment(router)
                .environment(lock)
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
        let synced = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.iosipratama.BitcoinTracker")
        )
        if let container = try? ModelContainer(for: schema, configurations: synced) {
            return container
        }

        // Losing sync is better than failing to open someone's wallets at all.
        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        return try! ModelContainer(for: schema, configurations: local)
    }()
}
