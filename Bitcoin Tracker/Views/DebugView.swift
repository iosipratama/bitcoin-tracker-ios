#if DEBUG
import SwiftUI
import SwiftData

/// A private testing surface, compiled out of release builds. Everything here
/// re-arms or overrides state the app is otherwise meant to reach only by
/// using it normally.
struct DebugView: View {
    @AppStorage(AppStorageKey.hasCompletedWelcome) private var hasCompletedWelcome = false
    @AppStorage(AppStorageKey.forcesEmptyState) private var forcesEmptyState = false
    @Environment(StoreManager.self) private var store
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var showPaywall = false
    @State private var confirmsSampleWallets = false
    @Environment(\.modelContext) private var modelContext
    private let sync = CloudSyncMonitor.shared
    @State private var clipboardTypes = Self.currentClipboardTypes()

    private static func currentClipboardTypes() -> String {
        let types = UIPasteboard.general.types
        return types.isEmpty ? "Empty" : types.joined(separator: "\n")
    }

    private var setupFailureText: String {
        if let failure = sync.setupFailure {
            return "Running local-only. Store failed to open with iCloud: \(failure)"
        }
        return "Upload should read OK a few seconds after any edit."
    }

    private func syncRow(_ symbol: String, _ title: String, _ value: String) -> some View {
        SettingsRow(systemImage: symbol, title: title) {
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(.secondaryLabel)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    var body: some View {
        @Bindable var store = store
        @Bindable var viewModel = viewModel

        return ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SettingsGroup(
                    title: "Flip to hide",
                    footer: "The simulator has no accelerometer, so the override is the only way to see the masking there."
                ) {
                    SettingsRow(systemImage: "eye.slash", title: "Force hidden balances") {
                        Toggle("Force hidden balances", isOn: $viewModel.forcesHiddenBalances)
                            .labelsHidden()
                            .tint(.brand)
                    }

                    SettingsRow(systemImage: "iphone.gen3", title: "Gravity") {
                        Text(viewModel.flipReadout)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondaryLabel)
                    }

                    SettingsRow(systemImage: "dot.radiowaves.left.and.right", title: "Monitoring") {
                        Text(viewModel.isMonitoringFlip ? "yes" : "no")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondaryLabel)
                    }
                }

                SettingsGroup(
                    title: "iCloud sync",
                    footer: setupFailureText
                ) {
                    syncRow("person.icloud", "Account", sync.accountStatus)
                    syncRow("gearshape", "Setup", sync.lastSetup)
                    syncRow("icloud.and.arrow.up", "Upload", sync.lastExport)
                    syncRow("icloud.and.arrow.down", "Download", sync.lastImport)
                }
                .task { await sync.refreshAccountStatus() }

                SettingsGroup(
                    title: "Clipboard",
                    footer: "The formats on the clipboard right now. Reading the list doesn't read the contents, so it never asks to paste."
                ) {
                    syncRow("doc.on.clipboard", "Formats", clipboardTypes)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    clipboardTypes = Self.currentClipboardTypes()
                }

                SettingsGroup(
                    title: "Screenshots",
                    footer: "Replaces every wallet with four real addresses, named and coloured for App Store screenshots. Balances are live, so they move."
                ) {
                    Button {
                        confirmsSampleWallets = true
                    } label: {
                        SettingsRow(systemImage: "photo.on.rectangle", title: "Load sample wallets") {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)
                }

                SettingsGroup(title: "Main view") {
                    SettingsRow(systemImage: "tray", title: "Force empty state") {
                        Toggle("Force empty state", isOn: $forcesEmptyState)
                            .labelsHidden()
                            .tint(.brand)
                    }
                }

                SettingsGroup(title: "Purchases") {
                    Button {
                        showPaywall = true
                    } label: {
                        SettingsRow(systemImage: "creditcard", title: "Show paywall") {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)

                    SettingsRow(systemImage: "lock.open", title: "Fake unlock") {
                        Toggle("Fake unlock", isOn: $store.fakesUnlock)
                            .labelsHidden()
                            .tint(.brand)
                    }

                    SettingsRow(systemImage: "plus.circle", title: "Always show paywall") {
                        Toggle("Always show paywall", isOn: $store.forcesPaywall)
                            .labelsHidden()
                            .tint(.brand)
                    }
                }

                SettingsGroup(title: "One-time prompts") {
                    Button {
                        withAnimation(.smooth) { hasCompletedWelcome = false }
                    } label: {
                        SettingsRow(systemImage: "hand.wave", title: "Show welcome screen") {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        ReviewPrompt.reset()
                    } label: {
                        SettingsRow(systemImage: "star", title: "Re-arm review prompt") {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(.appBackground)
        .navigationTitle("Debug")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
        .confirmationDialog("Replace all wallets with samples?", isPresented: $confirmsSampleWallets, titleVisibility: .visible) {
            Button("Replace Wallets", role: .destructive) { loadSampleWallets() }
        }
    }

    private func loadSampleWallets() {
        let wallets = SampleWallet.replaceAll(in: modelContext)
        Task { await viewModel.refreshBalances(wallets: wallets) }
    }
}

/// Opens the app on one screen for an App Store screenshot, since the
/// simulator can be launched from the command line but not tapped from it.
/// Launch with `-screenshotScene detail` (or home, addWallet, settings), and
/// `-loadSampleWallets YES` to start from the sample wallets.
enum ScreenshotScene: String {
    case home, detail, addWallet, settings

    static var current: ScreenshotScene? {
        UserDefaults.standard.string(forKey: "screenshotScene").flatMap(ScreenshotScene.init(rawValue:))
    }

    static var loadsSampleWallets: Bool {
        UserDefaults.standard.bool(forKey: "loadSampleWallets")
    }
}

struct SampleWallet {
    var name: String
    var symbol: WalletSymbol
    var accent: WalletAccent
    var address: String
    var goalSatoshis: Int64?
    /// Shown instead of the live balance in screenshot mode. The real
    /// addresses are busy and always mid-transaction, which reads as noise.
    var demoSatoshis: Int64

    /// Demo balances and goals match the iPhone screenshots: 41%, 6%, 17%.
    static let all = [
        SampleWallet(name: "house down payment", symbol: .home, accent: .mint,
                     address: "bc1qvmw9dmensxtuxu5vw7mxtxqurad2u99pdj9wwa",
                     goalSatoshis: 36_000_000, demoSatoshis: 14_682_310),
        SampleWallet(name: "retire early", symbol: .holiday, accent: .orange,
                     address: "bc1qq9qx0jj6glxe7dcgj98uke8yr4ze7sadt2qjgj",
                     goalSatoshis: 140_000_000, demoSatoshis: 8_412_370),
        SampleWallet(name: "emran's college", symbol: .education, accent: .cyan,
                     address: "bc1qc7s0je43r88p3zganwmfg862w9xm9qyeprqp7c",
                     goalSatoshis: 19_000_000, demoSatoshis: 3_156_842),
        SampleWallet(name: "family savings", symbol: .parent, accent: .mint,
                     address: "bc1qca3522yshz3t2m6aj92c6dvnc74x2seuqpwgat",
                     goalSatoshis: nil, demoSatoshis: 584_120),
    ]

    /// Fortnightly buys from two exchanges and one spend, adding up to less
    /// than the balance so the history reads as part of a longer one.
    static func demoActivity(for sample: SampleWallet) -> [ActivityItem] {
        let sources = [
            "bc1qm34lsc65zpw79lxes69zkqmk6ee3ewf0j77s3h",
            "bc1qjasf9z3h7w3jspkhtgatgpyvvzgpa2wwd2lr0eh5tx44reyn2k7sfc27a4",
            "3FupZp77ySr7jwoLYEJ9mwzJpvoNBXsBnE",
        ]
        let step = max(sample.demoSatoshis / 24, 10_000)
        let amounts: [Int64] = [3, 2, 4, 2, -1, 3, 2, 3, 2, 4].map { $0 * step }
        return amounts.enumerated().map { index, amount in
            ActivityItem(
                id: "demo-\(sample.address)-\(index)",
                netSatoshis: amount,
                date: .now.addingTimeInterval(-Double(index * 14 + 2) * 86_400),
                counterparty: sources[index % sources.count]
            )
        }
    }

    /// An address not among the samples, for the paste screen.
    static let pasteExample = "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"

    @discardableResult
    static func replaceAll(in context: ModelContext, demo: Bool = false) -> [Wallet] {
        for wallet in (try? context.fetch(FetchDescriptor<Wallet>())) ?? [] {
            context.delete(wallet)
        }

        // Staggered so Home lists them in this order, which sorts by creation.
        let wallets = all.enumerated().map { index, sample in
            let wallet = Wallet(name: sample.name)
            wallet.createdAt = .now.addingTimeInterval(Double(index - all.count))
            wallet.symbol = sample.symbol
            wallet.accent = sample.accent
            wallet.goalSatoshis = sample.goalSatoshis
            let address = BitcoinAddress(address: sample.address)
            if demo {
                address.balanceSatoshis = sample.demoSatoshis
                address.lastUpdated = .now
            }
            wallet.add(address)
            context.insert(wallet)
            return wallet
        }
        try? context.save()
        return wallets
    }
}
#endif
