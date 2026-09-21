import SwiftUI
import WidgetKit

/// Progress, and nothing else. No balance, no fiat — a goal is the one figure
/// that is safe to leave on a Home Screen, and the one worth glancing at when
/// the amounts themselves are none of the room's business.
struct GoalWidgetView: View {
    let entry: WalletEntry

    private let ringSize: CGFloat = 76
    private let tileSize: CGFloat = 34

    var body: some View {
        if let wallet = entry.wallet {
            content(wallet)
        } else {
            WidgetEmptyState()
        }
    }

    private func content(_ wallet: WalletSnapshot) -> some View {
        VStack(spacing: 0) {
            ZStack {
                GoalRing(progress: wallet.goalProgress ?? 0, size: ringSize)
                WalletSymbolTile(symbol: wallet.symbol, accent: wallet.accent, size: tileSize)
            }

            Spacer(minLength: 10)

            Text(wallet.name)
                .font(.walletName)
                .foregroundStyle(Custom.labelSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            caption(wallet)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .fontDesign(.rounded)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(wallet))
    }

    @ViewBuilder
    private func caption(_ wallet: WalletSnapshot) -> some View {
        if let progress = wallet.goalProgress {
            Text(captionText(progress))
                .font(.walletFiat)
                .foregroundStyle(.brand)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else {
            Text("No goal set")
                .font(.walletFiat)
                .foregroundStyle(Custom.labelTertiary)
                .lineLimit(1)
        }
    }

    /// "to goal" while there is still distance to cover, "of goal" once there
    /// isn't — the percentage stays uncapped either way, because overshooting
    /// is the reward for holding.
    private func captionText(_ progress: Double) -> String {
        let percent = entry.formatter.formattedGoalPercent(progress)
        return progress >= 1 ? "\(percent) of goal" : "\(percent) to goal"
    }

    private func accessibilityLabel(_ wallet: WalletSnapshot) -> String {
        guard let progress = wallet.goalProgress else {
            return "\(wallet.name), no goal set"
        }
        return "\(wallet.name), \(captionText(progress))"
    }
}
