import SwiftUI

struct WalletCard: View {
    let wallet: Wallet
    let viewModel: PortfolioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(wallet.name)
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    AnimatingNumber(value: viewModel.fiatValue(btc: wallet.totalBTC)) { val in
                        viewModel.formattedFiat(val)
                    }
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                    Text(viewModel.formattedBTC(wallet.totalBTC))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(wallet.addresses.count) address\(wallet.addresses.count == 1 ? "" : "es")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
