import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidAddress
    case rateLimited
    case unreachable
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
        case .unreachable:
            "Can't reach a block explorer. Check your connection — some networks block them."
        case .networkError(let error):
            error.localizedDescription
        case .decodingError:
            "Failed to parse response"
        case .httpError(let code):
            "Server error (\(code))"
        }
    }
}

/// The shape mempool.space and every other Esplora-compatible explorer returns
/// for `/address/{address}`.
struct EsploraAddressResponse: Decodable, Sendable {
    let chain_stats: Stats
    let mempool_stats: Stats

    struct Stats: Decodable, Sendable {
        let funded_txo_sum: Int64
        let spent_txo_sum: Int64

        /// Funded minus spent. Negative in mempool_stats when a spend is pending.
        var delta: Int64 { funded_txo_sum - spent_txo_sum }
    }
}

actor BitcoinAPIService {
    static let shared = BitcoinAPIService()

    /// mempool.space is the primary. The rest serve the identical Esplora API and
    /// exist because some ISPs and networks block block-explorer domains outright;
    /// without a fallback the app is simply dead on those connections.
    private static let endpoints = [
        "https://mempool.space/api",
        "https://mempool.emzy.de/api",
        "https://blockstream.info/api",
    ]

    private let session: URLSession

    /// The endpoint that last answered, tried first next time. Without this a
    /// blocked primary costs a timeout on every single request instead of one.
    private var preferredEndpoint = 0

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    func fetchBalance(for address: String) async throws -> AddressBalance {
        let count = Self.endpoints.count
        var lastError: Error?

        for step in 0..<count {
            let index = (preferredEndpoint + step) % count
            do {
                let balance = try await Self.fetchBalance(
                    for: address,
                    from: Self.endpoints[index],
                    session: session
                )
                preferredEndpoint = index
                return balance
            } catch APIError.invalidAddress {
                // Every mirror reads the same chain, so this verdict is final.
                throw APIError.invalidAddress
            } catch {
                lastError = error
            }
        }

        throw lastError.map { error in
            (error as? URLError) != nil ? APIError.unreachable : error
        } ?? APIError.unreachable
    }

    /// Runs off the actor: it touches no mutable state, so balance fetches for
    /// different addresses overlap freely.
    private static func fetchBalance(
        for address: String,
        from endpoint: String,
        session: URLSession
    ) async throws -> AddressBalance {
        guard let encoded = address.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let url = URL(string: "\(endpoint)/address/\(encoded)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        switch http.statusCode {
        case 200: break
        case 400, 404: throw APIError.invalidAddress
        case 429: throw APIError.rateLimited
        default: throw APIError.httpError(http.statusCode)
        }

        guard let decoded = try? JSONDecoder().decode(EsploraAddressResponse.self, from: data) else {
            throw APIError.decodingError
        }

        return AddressBalance(
            confirmedSatoshis: decoded.chain_stats.delta,
            pendingSatoshis: decoded.mempool_stats.delta
        )
    }
}
