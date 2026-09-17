import SwiftUI

struct WalletRow: View {
    let wallet: Wallet

    @Environment(PortfolioViewModel.self) private var viewModel

    private var balance: AddressBalance { wallet.balance }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            balancePanel
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                .fill(.cardBackground)
        )
        // Applied once here; every Text below inherits the rounded design.
        .fontDesign(.rounded)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(wallet.accent.color)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: wallet.symbol.systemName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.onAccent)
                }
                .accessibilityHidden(true)

            Text(wallet.name)
                .font(.walletName)
                .foregroundStyle(.label)

            Spacer(minLength: 0)
        }
    }

    private var balancePanel: some View {
        VStack(alignment: .leading, spacing: 3) {
            // ₿ and ≡ are literal characters rather than SF Symbols so they sit
            // on the text baseline and pick up the rounded design.
            HStack(spacing: 6) {
                Text("\u{20BF}")
                    .font(.walletBalance)
                    .foregroundStyle(.secondaryLabel)

                Text(wallet.totalBTC.btcDigits)
                    .font(.walletBalance)
                    .foregroundStyle(.label)
            }

            if viewModel.showsFiatValues {
                HStack(spacing: 6) {
                    Text("\u{2261}")
                        .font(.walletFiat)
                        .foregroundStyle(.tertiaryLabel)

                    Text(viewModel.formattedFiatWhole(viewModel.fiatValue(btc: wallet.totalBTC)))
                        .font(.walletFiat)
                        .foregroundStyle(.secondaryLabel)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: .rowRadius, style: .continuous)
                .fill(.cardInsetBackground)
        )
    }
}
