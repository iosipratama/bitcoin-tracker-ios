import SwiftUI

struct WalletRow: View {
    let wallet: Wallet

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(wallet.name)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.textSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(formattedBTC)
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)

                Text("BTC")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .contentShape(Rectangle())
    }

    private var formattedBTC: String {
        let btc = wallet.totalBTC
        if btc == 0 { return "0.00000000" }
        if btc >= 1 { return String(format: "%.4f", btc) }
        return String(format: "%.8f", btc)
    }
}

// MARK: - Previews

#Preview("Single row") {
    let wallet = Wallet(name: "Cold Storage")
    let a = BitcoinAddress(address: "bc1q")
    a.balanceSatoshis = 105_340_200
    wallet.addresses.append(a)

    return WalletRow(wallet: wallet)
        .background(Color.appBackground)
}

#Preview("Two rows") {
    let w1 = Wallet(name: "Family saving")
    let a1 = BitcoinAddress(address: "bc1q")
    a1.balanceSatoshis = 12_221_303
    w1.addresses.append(a1)

    let w2 = Wallet(name: "Anna")
    let a2 = BitcoinAddress(address: "bc1q2")
    a2.balanceSatoshis = 1_221_303
    w2.addresses.append(a2)

    return VStack(spacing: 0) {
        WalletRow(wallet: w1)
        Rectangle().fill(Color.rowDivider).frame(height: 0.5)
        WalletRow(wallet: w2)
    }
    .background(Color.appBackground)
}
