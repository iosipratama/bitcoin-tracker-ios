import AppIntents

/// The one thing either widget asks: which wallet.
struct SelectWalletIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Choose Wallet" }
    static var description: IntentDescription {
        IntentDescription("Pick the wallet this widget follows.")
    }

    @Parameter(title: "Wallet")
    var wallet: WalletEntity?

    init() {}

    init(wallet: WalletEntity?) {
        self.wallet = wallet
    }
}
