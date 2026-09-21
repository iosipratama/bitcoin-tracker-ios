import SwiftUI
import WidgetKit

/// The wallet card, restacked for a square. The tile and name sit at the top,
/// the figures settle at the bottom, and the space between them is what makes
/// a balance feel like something you can leave alone.
struct BalanceWidgetView: View {
    let entry: WalletEntry

    private var formatter: BalanceFormatter { entry.formatter }

    var body: some View {
        if let wallet = entry.wallet {
            content(wallet)
        } else {
            WidgetEmptyState()
        }
    }

    private func content(_ wallet: WalletSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            WalletSymbolTile(symbol: wallet.symbol, accent: wallet.accent, size: 26)
                .padding(.bottom, 8)

            Text(wallet.name)
                .font(.walletName)
                .foregroundStyle(Custom.labelSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            balanceLine(wallet)

            if formatter.showsFiatValues {
                fiatLine(wallet)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // Set once for the whole widget, exactly as the card does it.
        .fontDesign(.rounded)
        .privacySensitive()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(wallet.name), \(formatter.formattedBTC(wallet.totalBTC))")
    }

    /// ₿ and ≡ are literal characters rather than SF Symbols so they sit on the
    /// text baseline and pick up the rounded design.
    private func balanceLine(_ wallet: WalletSnapshot) -> some View {
        HStack(spacing: 4) {
            if let prefix = formatter.amountPrefix {
                Text(prefix)
                    .font(.walletBalanceMark)
                    .foregroundStyle(Custom.labelTertiary)
            }

            Text(formatter.formattedAmount(btc: wallet.totalBTC))
                .font(.walletBalance)
                .foregroundStyle(.label)

            if let suffix = formatter.amountSuffix {
                Text(suffix)
                    .font(.walletFiat)
                    .foregroundStyle(Custom.labelTertiary)
            }
        }
        .lineLimit(1)
        // Satoshi mode runs to eight grouped digits on a stack this app is
        // built for, and a truncated balance is worse than a small one.
        .minimumScaleFactor(0.6)
    }

    private func fiatLine(_ wallet: WalletSnapshot) -> some View {
        HStack(spacing: 2) {
            Text("\u{2261}")
                .font(.walletFiat)
                .foregroundStyle(Custom.labelTertiary)

            Text(formatter.formattedFiatWhole(formatter.fiatValue(btc: wallet.totalBTC)))
                .font(.walletFiat)
                .foregroundStyle(Custom.labelTertiary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}
