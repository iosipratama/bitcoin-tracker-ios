import Foundation

nonisolated enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidAddress
    case rateLimited
    case unreachable
    case networkError(String)
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
            "Couldn’t reach a block explorer."
        case .networkError(let message):
            message
        case .decodingError:
            "Failed to parse response"
        case .httpError(let code):
            "Server error (\(code))"
        }
    }

    var isTransport: Bool {
        if case .unreachable = self { return true }
        return false
    }
}

/// The shape mempool.space and every other Esplora-compatible explorer returns
/// for `/address/{address}`.
nonisolated struct EsploraAddressResponse: Decodable, Sendable {
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

    /// How long a host gets to itself before the next one is raced against it.
    /// Long enough that a healthy primary always wins alone and no redundant
    /// request is ever sent; short enough that a blocked host isn't waited out.
    private static let hedgeDelay = Duration.milliseconds(1500)

    private static let preferredKey = "preferredBalanceEndpoint"

    private let session: URLSession

    /// Persisted, because in memory alone it reset on every launch — which on a
    /// network that blocks the primary meant eating the full timeout each time
    /// the app was opened.
    private var preferredEndpoint: Int {
        didSet {
            guard preferredEndpoint != oldValue else { return }
            UserDefaults.standard.set(preferredEndpoint, forKey: Self.preferredKey)
        }
    }

    private init() {
        let stored = UserDefaults.standard.object(forKey: Self.preferredKey) as? Int
        preferredEndpoint = Self.endpoints.indices.contains(stored ?? -1) ? stored! : 0

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    func fetchBalance(for address: String) async throws -> AddressBalance {
        let order = Self.endpoints.indices.map { (preferredEndpoint + $0) % Self.endpoints.count }

        switch await Self.race(address: address, order: order, session: session) {
        case .success(let index, let balance):
            preferredEndpoint = index
            return balance
        case .failure(let error):
            throw error
        }
    }

    private enum RaceOutcome: Sendable {
        case success(Int, AddressBalance)
        case failure(APIError)
    }

    private enum EndpointOutcome: Sendable {
        case success(Int, AddressBalance)
        case failure(APIError)
        case skipped
    }

    /// Hedged request. Each host starts one `hedgeDelay` after the previous, and
    /// the first success cancels the rest — so a responsive primary answers alone
    /// and a dead one costs 1.5s instead of the full 8s timeout.
    private nonisolated static func race(
        address: String,
        order: [Int],
        session: URLSession
    ) async -> RaceOutcome {
        await withTaskGroup(of: EndpointOutcome.self) { group in
            for (position, index) in order.enumerated() {
                group.addTask {
                    if position > 0 {
                        // Cancelled before firing when an earlier host already won.
                        guard (try? await Task.sleep(for: hedgeDelay * position)) != nil else {
                            return .skipped
                        }
                    }
                    guard !Task.isCancelled else { return .skipped }

                    do {
                        let balance = try await fetchBalance(
                            for: address,
                            from: endpoints[index],
                            session: session
                        )
                        return .success(index, balance)
                    } catch let error as APIError {
                        return .failure(error)
                    } catch {
                        return .failure(.unreachable)
                    }
                }
            }

            var errors: [APIError] = []

            for await outcome in group {
                switch outcome {
                case .success(let index, let balance):
                    group.cancelAll()
                    return .success(index, balance)
                case .failure(.invalidAddress):
                    // Every mirror reads the same chain, so this verdict is final.
                    group.cancelAll()
                    return .failure(.invalidAddress)
                case .failure(let error):
                    errors.append(error)
                case .skipped:
                    continue
                }
            }

            // A real server complaint is more use to the reader than "unreachable".
            return .failure(errors.first { !$0.isTransport } ?? .unreachable)
        }
    }

    private nonisolated static func fetchBalance(
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
            throw APIError.networkError(URLError(.badServerResponse).localizedDescription)
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
