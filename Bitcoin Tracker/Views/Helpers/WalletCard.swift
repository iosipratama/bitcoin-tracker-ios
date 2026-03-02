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
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Text("\(wallet.addresses.count) address\(wallet.addresses.count == 1 ? "" : "es")")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: .cardRadius)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: .cardRadius)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
#Preview {
    let wallet = Wallet(name: "Personal")
    let address = BitcoinAddress(address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh")
    address.balanceSatoshis = 75_000_000 // 0.75 BTC
    wallet.addresses.append(address)
    
    let viewModel = PortfolioViewModel()
    
    return WalletCard(wallet: wallet, viewModel: viewModel)
        .padding()
        .background(Color(hex: 0x0A0A0A))
}

