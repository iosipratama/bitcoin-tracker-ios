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

/// The parts of an Esplora transaction needed to tell how much it moved in or
/// out of a given set of addresses. Everything else in the response is ignored.
nonisolated struct EsploraTransaction: Decodable, Sendable {
    let txid: String
    let status: Status
    let vin: [Input]
    let vout: [Output]

    struct Status: Decodable, Sendable {
        let confirmed: Bool
        let block_time: TimeInterval?
    }

    struct Input: Decodable, Sendable {
        /// nil on a coinbase input, which spends nothing.
        let prevout: Output?
    }

    struct Output: Decodable, Sendable {
        let scriptpubkey_address: String?
        let value: Int64
    }

    /// What landed in `addresses` minus what left them. Measured against the
    /// whole set, so coins moved between two addresses of one wallet net out to
    /// the fee rather than reading as both a send and a receipt.
    func netSatoshis(for addresses: Set<String>) -> Int64 {
        let received = vout
            .filter { $0.scriptpubkey_address.map(addresses.contains) ?? false }
            .reduce(0) { $0 + $1.value }
        let spent = vin
            .compactMap(\.prevout)
            .filter { $0.scriptpubkey_address.map(addresses.contains) ?? false }
            .reduce(0) { $0 + $1.value }
        return received - spent
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
    /// the app was opened. Kept in the shared suite so the widget starts from
    /// whichever explorer the app last found answering, rather than learning
    /// the same lesson again in its own process.
    private var preferredEndpoint: Int {
        didSet {
            guard preferredEndpoint != oldValue else { return }
            AppGroup.defaults.set(preferredEndpoint, forKey: Self.preferredKey)
        }
    }

    private init() {
        let stored = AppGroup.defaults.object(forKey: Self.preferredKey) as? Int
        preferredEndpoint = Self.endpoints.indices.contains(stored ?? -1) ? stored! : 0

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    func fetchBalance(for address: String) async throws -> AddressBalance {
        try await hedged { endpoint, session in
            let data = try await Self.get("\(endpoint)/address/\(try Self.encoded(address))", session: session)
            guard let decoded = try? JSONDecoder().decode(EsploraAddressResponse.self, from: data) else {
                throw APIError.decodingError
            }
            return AddressBalance(
                confirmedSatoshis: decoded.chain_stats.delta,
                pendingSatoshis: decoded.mempool_stats.delta
            )
        }
    }

    /// Pending transactions first, then the latest confirmed ones — up to 50
    /// and 25 respectively, which is one page and far more than Recent Activity
    /// shows.
    func fetchTransactions(for address: String) async throws -> [EsploraTransaction] {
        try await hedged { endpoint, session in
            let data = try await Self.get("\(endpoint)/address/\(try Self.encoded(address))/txs", session: session)
            guard let decoded = try? JSONDecoder().decode([EsploraTransaction].self, from: data) else {
                throw APIError.decodingError
            }
            return decoded
        }
    }

    private func hedged<Value: Sendable>(
        _ fetch: @escaping @Sendable (String, URLSession) async throws -> Value
    ) async throws -> Value {
        let order = Self.endpoints.indices.map { (preferredEndpoint + $0) % Self.endpoints.count }

        switch await Self.race(order: order, session: session, fetch: fetch) {
        case .success(let index, let value):
            preferredEndpoint = index
            return value
        case .failure(let error):
            throw error
        }
    }

    private enum RaceOutcome<Value: Sendable>: Sendable {
        case success(Int, Value)
        case failure(APIError)
    }

    private enum EndpointOutcome<Value: Sendable>: Sendable {
        case success(Int, Value)
        case failure(APIError)
        case skipped
    }

    /// Hedged request. Each host starts one `hedgeDelay` after the previous, and
    /// the first success cancels the rest — so a responsive primary answers alone
    /// and a dead one costs 1.5s instead of the full 8s timeout.
    private nonisolated static func race<Value: Sendable>(
        order: [Int],
        session: URLSession,
        fetch: @escaping @Sendable (String, URLSession) async throws -> Value
    ) async -> RaceOutcome<Value> {
        await withTaskGroup(of: EndpointOutcome<Value>.self) { group in
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
                        return .success(index, try await fetch(endpoints[index], session))
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
                case .success(let index, let value):
                    group.cancelAll()
                    return .success(index, value)
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

    private nonisolated static func encoded(_ address: String) throws -> String {
        guard let encoded = address.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            throw APIError.invalidURL
        }
        return encoded
    }

    private nonisolated static func get(_ string: String, session: URLSession) async throws -> Data {
        guard let url = URL(string: string) else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse).localizedDescription)
        }

        switch http.statusCode {
        case 200: return data
        case 400, 404: throw APIError.invalidAddress
        case 429: throw APIError.rateLimited
        default: throw APIError.httpError(http.statusCode)
        }
    }
}
