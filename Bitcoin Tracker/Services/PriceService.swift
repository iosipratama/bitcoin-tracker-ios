import Foundation

enum FiatCurrency: String, CaseIterable, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"

    var symbol: String {
        switch self {
        case .usd: "$"
        case .eur: "€"
        case .gbp: "£"
        }
    }

    var locale: Locale {
        switch self {
        case .usd: Locale(identifier: "en_US")
        case .eur: Locale(identifier: "de_DE")
        case .gbp: Locale(identifier: "en_GB")
        }
    }
}

struct CoinGeckoPriceResponse: Decodable {
    let bitcoin: [String: Double]
}

actor PriceService {
    static let shared = PriceService()

    private let session: URLSession
    private let priceURL = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd,eur,gbp"

    private var cachedPrices: [String: Double] = [:]
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 60 // 1 minute cache

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    func fetchPrices() async throws -> [String: Double] {
        if let lastFetch, let cached = cachedPrices as [String: Double]?,
           !cached.isEmpty, Date.now.timeIntervalSince(lastFetch) < cacheInterval {
            return cached
        }

        guard let url = URL(string: priceURL) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        guard let decoded = try? JSONDecoder().decode(CoinGeckoPriceResponse.self, from: data) else {
            throw APIError.decodingError
        }

        cachedPrices = decoded.bitcoin
        lastFetch = .now
        return decoded.bitcoin
    }

    func price(for currency: FiatCurrency) async throws -> Double {
        let prices = try await fetchPrices()
        guard let price = prices[currency.rawValue.lowercased()] else {
            throw APIError.decodingError
        }
        return price
    }
}
