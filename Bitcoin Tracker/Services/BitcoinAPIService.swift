import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidAddress
    case rateLimited
    case networkError(Error)
    case decodingError
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        case .invalidAddress:
            "Address not recognized"
        case .rateLimited:
            "Too many requests — try again shortly"
        case .networkError(let error):
            error.localizedDescription
        case .decodingError:
            "Failed to parse response"
        case .httpError(let code):
            "Server error (\(code))"
        }
    }
}

struct BlockstreamAddressResponse: Decodable, Sendable {
    let chain_stats: ChainStats

    struct ChainStats: Decodable, Sendable {
        let funded_txo_sum: Int64
        let spent_txo_sum: Int64
    }
}

actor BitcoinAPIService {
    static let shared = BitcoinAPIService()

    private let session: URLSession
    private let baseURL = "https://blockstream.info/api"

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // nonisolated: this path touches only immutable state, so it needs no actor hop.
    nonisolated func fetchBalance(for address: String) async throws -> Int64 {
        guard let encoded = address.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let url = URL(string: "\(baseURL)/address/\(encoded)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200: break
        case 400, 404: throw APIError.invalidAddress
        case 429: throw APIError.rateLimited
        default: throw APIError.httpError(httpResponse.statusCode)
        }

        guard let decoded = try? JSONDecoder().decode(BlockstreamAddressResponse.self, from: data) else {
            throw APIError.decodingError
        }

        return decoded.chain_stats.funded_txo_sum - decoded.chain_stats.spent_txo_sum
    }
}
