import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class PortfolioViewModel {
    var isLoading = false
    var priceError: String?
    var btcPrice: Double = 0
    var prices: [String: Double] = [:]

    var selectedCurrency: FiatCurrency {
        get {
            if let raw = UserDefaults.standard.string(forKey: "selectedCurrency"),
               let currency = FiatCurrency(rawValue: raw) {
                return currency
            }
            return .usd
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedCurrency")
        }
    }

    var currentPrice: Double {
        prices[selectedCurrency.rawValue.lowercased()] ?? 0
    }

    func fiatValue(btc: Double) -> Double {
        btc * currentPrice
    }

    func formattedBTC(_ value: Double) -> String {
        String(format: "%.8f BTC", value)
    }

    func formattedFiat(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = selectedCurrency.locale
        formatter.currencyCode = selectedCurrency.rawValue
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(selectedCurrency.symbol)\(value)"
    }

    func refreshPrices() async {
        do {
            prices = try await PriceService.shared.fetchPrices()
            btcPrice = currentPrice
            priceError = nil
        } catch {
            priceError = error.localizedDescription
        }
    }

    func refreshBalances(wallets: [Wallet]) async {
        isLoading = true
        defer { isLoading = false }

        await refreshPrices()

        await withTaskGroup(of: Void.self) { group in
            for wallet in wallets {
                for address in wallet.addresses {
                    group.addTask {
                        await self.fetchBalance(for: address)
                    }
                }
            }
        }
    }

    func fetchBalance(for address: BitcoinAddress) async {
        do {
            let satoshis = try await BitcoinAPIService.shared.fetchBalance(for: address.address)
            address.balanceSatoshis = satoshis
            address.lastUpdated = .now
            address.fetchError = nil
        } catch {
            address.fetchError = error.localizedDescription
        }
    }
}
