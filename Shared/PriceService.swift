import Foundation

nonisolated struct CoinGeckoPriceResponse: Decodable, Sendable {
    let bitcoin: [String: Double]
}

actor PriceService {
    static let shared = PriceService()

    private let session: URLSession
    private let priceURL = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies="
        + FiatCurrency.allCases.map(\.apiKey).joined(separator: ",")

    private var cachedPrices: [String: Double] = [:]
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 60 // 1 minute cache

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    func fetchPrices() async throws -> [String: Double] {
        if let lastFetch, !cachedPrices.isEmpty,
           Date.now.timeIntervalSince(lastFetch) < cacheInterval {
            return cachedPrices
        }

        guard let url = URL(string: priceURL) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse).localizedDescription)
        }

        switch httpResponse.statusCode {
        case 200: break
        case 429: throw APIError.rateLimited
        default: throw APIError.httpError(httpResponse.statusCode)
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
        guard let price = prices[currency.apiKey] else {
            throw APIError.decodingError
        }
        return price
    }
}
