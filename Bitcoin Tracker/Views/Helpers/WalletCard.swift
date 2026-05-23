import SwiftUI

struct WalletCard: View {
    let wallet: Wallet
    // Goal — will be model-driven later
    var goalSatoshis: Int64? = nil

    private var totalSatoshis: Int64 { wallet.totalSatoshis }
    private var totalBTC: Double { wallet.totalBTC }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Label at top
            Text(wallet.name.uppercased())
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .kerning(0.8)

            Spacer(minLength: 16)

            // BTC number — large, mixed sizing, fills the card
            btcDisplay

            // Sats secondary
            Text(satsFormatted)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.textSecondary)
                .monospacedDigit()
                .padding(.top, 5)

            // Goal bar — only when set
            if let goal = goalSatoshis {
                goalBar(goal: goal)
                    .padding(.top, 20)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }

    // MARK: - BTC display

    private var btcDisplay: some View {
        Group {
            if let goal = goalSatoshis {
                // Pattern: "0.215 /1 BTC" — current / goal mixed sizing
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text(formattedBTC)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    Text(" /\(formattedGoalBTC(goal))")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.textSecondary)
                        .monospacedDigit()

                    Text(" BTC")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
            } else {
                // Pattern: "0.21500000 BTC" — plain
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(formattedBTC)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    Text("BTC")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    // MARK: - Goal bar

    private func goalBar(goal: Int64) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.rowDivider)
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.bitcoinOrange)
                        .frame(width: geo.size.width * progressRatio(goal: goal), height: 3)
                }
            }
            .frame(height: 3)

            Text(progressPercent(goal: goal))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.bitcoinOrange)
                .monospacedDigit()
        }
    }

    // MARK: - Formatting

    private var formattedBTC: String {
        if totalBTC == 0 { return "0.00" }
        if totalBTC >= 1 { return String(format: "%.4f", totalBTC) }
        return String(format: "%.8f", totalBTC)
    }

    private var satsFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let str = formatter.string(from: NSNumber(value: totalSatoshis)) ?? "\(totalSatoshis)"
        return "\(str) sats"
    }

    private func formattedGoalBTC(_ sats: Int64) -> String {
        let btc = Double(sats) / 100_000_000
        if btc == Double(Int(btc)) { return String(format: "%.0f", btc) }
        if btc >= 0.1 { return String(format: "%.2f", btc) }
        return String(format: "%.8f", btc)
    }

    private func progressRatio(goal: Int64) -> CGFloat {
        guard goal > 0 else { return 0 }
        return min(CGFloat(totalSatoshis) / CGFloat(goal), 1.0)
    }

    private func progressPercent(goal: Int64) -> String {
        let ratio = min(Double(totalSatoshis) / Double(max(goal, 1)) * 100, 100)
        if ratio < 1 { return String(format: "%.2f%%", ratio) }
        return String(format: "%.1f%%", ratio)
    }
}

// MARK: - Previews

#Preview("No Goal — Large stack") {
    let wallet = Wallet(name: "Cold Storage")
    let a = BitcoinAddress(address: "bc1q")
    a.balanceSatoshis = 105_340_200
    wallet.addresses.append(a)

    return WalletCard(wallet: wallet)
        .padding(20)
        .background(Color.appBackground)
}

#Preview("With Goal — In progress") {
    let wallet = Wallet(name: "Stack")
    let a = BitcoinAddress(address: "bc1q")
    a.balanceSatoshis = 21_500_000
    wallet.addresses.append(a)

    return WalletCard(wallet: wallet, goalSatoshis: 100_000_000)
        .padding(20)
        .background(Color.appBackground)
}

#Preview("With Goal — Early") {
    let wallet = Wallet(name: "Stack")
    let a = BitcoinAddress(address: "bc1q")
    a.balanceSatoshis = 1_250_000
    wallet.addresses.append(a)

    return WalletCard(wallet: wallet, goalSatoshis: 100_000_000)
        .padding(20)
        .background(Color.appBackground)
}

#Preview("Two cards") {
    let w1 = Wallet(name: "Stack")
    let a1 = BitcoinAddress(address: "bc1q")
    a1.balanceSatoshis = 21_500_000
    w1.addresses.append(a1)

    let w2 = Wallet(name: "Cold Storage")
    let a2 = BitcoinAddress(address: "bc1q2")
    a2.balanceSatoshis = 105_340_200
    w2.addresses.append(a2)

    return VStack(spacing: 12) {
        WalletCard(wallet: w1, goalSatoshis: 100_000_000)
        WalletCard(wallet: w2)
    }
    .padding(20)
    .background(Color.appBackground)
}
