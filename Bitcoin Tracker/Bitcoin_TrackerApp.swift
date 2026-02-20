import SwiftUI
import SwiftData

@main
struct Bitcoin_TrackerApp: App {
    @State private var viewModel = PortfolioViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(viewModel)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Wallet.self, BitcoinAddress.self])
    }
}
