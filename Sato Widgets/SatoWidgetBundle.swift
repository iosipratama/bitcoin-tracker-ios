import SwiftUI
import WidgetKit

@main
struct SatoWidgetBundle: WidgetBundle {
    var body: some Widget {
        WalletBalanceWidget()
        WalletGoalWidget()
    }
}

/// A wallet's balance on the Home Screen.
struct WalletBalanceWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "com.iosipratama.BitcoinTracker.WalletBalance",
            intent: SelectWalletIntent.self,
            provider: WalletTimelineProvider()
        ) { entry in
            BalanceWidgetView(entry: entry)
                .containerBackground(Custom.fillPrimary, for: .widget)
        }
        .configurationDisplayName("Wallet")
        .description("The balance of one wallet.")
        .supportedFamilies([.systemSmall])
    }
}

/// How far one wallet has come towards its goal.
struct WalletGoalWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "com.iosipratama.BitcoinTracker.WalletGoal",
            intent: SelectWalletIntent.self,
            provider: WalletTimelineProvider()
        ) { entry in
            GoalWidgetView(entry: entry)
                .containerBackground(Custom.fillPrimary, for: .widget)
        }
        .configurationDisplayName("Goal")
        .description("Progress towards one wallet's goal.")
        .supportedFamilies([.systemSmall])
    }
}
