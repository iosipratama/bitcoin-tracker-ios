import SwiftUI
import SwiftData

@main
struct Bitcoin_TrackerApp: App {
    @State private var viewModel = PortfolioViewModel()
    @State private var store = StoreManager()
    @State private var router = WidgetRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .environment(store)
                .environment(router)
                .task { await store.load() }
                .preferredColorScheme(viewModel.theme.colorScheme)
        }
        .modelContainer(for: [Wallet.self, BitcoinAddress.self])
    }
}
