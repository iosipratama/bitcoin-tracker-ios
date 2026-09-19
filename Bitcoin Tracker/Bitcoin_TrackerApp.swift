import SwiftUI
import SwiftData

@main
struct Bitcoin_TrackerApp: App {
    @State private var viewModel = PortfolioViewModel()
    @State private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .environment(store)
                .task { await store.load() }
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Wallet.self, BitcoinAddress.self])
    }
}
