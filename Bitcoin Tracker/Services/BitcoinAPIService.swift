import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
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

    func fetchBalance(for address: String) async throws -> Int64 {
        guard let url = URL(string: "\(baseURL)/address/\(address)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Decode outside actor isolation
        let decoded = try await Task {
            try JSONDecoder().decode(BlockstreamAddressResponse.self, from: data)
        }.value

        return decoded.chain_stats.funded_txo_sum - decoded.chain_stats.spent_txo_sum
    }
}
