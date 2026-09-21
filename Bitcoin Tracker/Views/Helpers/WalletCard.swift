import SwiftUI

struct WalletRow: View {
    let wallet: Wallet

    @Environment(PortfolioViewModel.self) private var viewModel

    /// The balance panel's internal padding. The header borrows it as leading
    /// padding so the symbol tile lines up with the ₿ directly beneath it.
    private let panelInset: CGFloat = 12

    private var balance: AddressBalance { wallet.balance }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            balancePanel
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                .fill(Custom.fillPrimary)
        )
        // Applied once here; every Text below inherits the rounded design.
        .fontDesign(.rounded)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        HStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(wallet.accent.color)
                .frame(width: 25, height: 25)
                .overlay {
                    Image(systemName: wallet.symbol.systemName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.onAccent)
                }
                .accessibilityHidden(true)

            Text(wallet.name)
                .font(.walletName)
                .foregroundStyle(Custom.labelSecondary)

            Spacer(minLength: 8)

            if let progress = wallet.goalProgress {
                HStack(spacing: 8) {
                    Text(viewModel.formattedGoalPercent(progress))
                        .font(.walletFiat)
                        .foregroundStyle(Custom.labelTertiary)

                    GoalRing(progress: progress, isHidden: viewModel.hidesBalances)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(.top, panelInset)
        .padding(.horizontal, panelInset)
    }

    private var balancePanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            // ₿ and ≡ are literal characters rather than SF Symbols so they sit
            // on the text baseline and pick up the rounded design.
            HStack(spacing: 4) {
                if let prefix = viewModel.amountPrefix {
                    Text(prefix)
                        .font(.walletBalanceMark)
                        .foregroundStyle(Custom.labelTertiary)
                }

                Text(viewModel.formattedAmount(btc: wallet.totalBTC))
                    .font(.walletBalance)
                    .foregroundStyle(.label)

                if let suffix = viewModel.amountSuffix {
                    Text(suffix)
                        .font(.walletFiat)
                        .foregroundStyle(Custom.labelTertiary)
                }
            }

            if viewModel.showsFiatValues {
                HStack(spacing: 2) {
                    Text("\u{2261}")
                        .font(.walletFiat)
                        .foregroundStyle(Custom.labelTertiary)

                    Text(viewModel.formattedFiatWhole(viewModel.fiatValue(btc: wallet.totalBTC)))
                        .font(.walletFiat)
                        .foregroundStyle(Custom.labelTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }

            if balance.hasPending {
                Text("\(viewModel.formattedPending(balance.pendingSatoshis)) pending")
                    .font(.caption)
                    .foregroundStyle(.brand)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(panelInset)
        .background(
            RoundedRectangle(cornerRadius: .cardInsetRadius, style: .continuous)
                .fill(Custom.backgroundBase)
        )
    }
}
