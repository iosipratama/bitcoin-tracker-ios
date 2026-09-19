import Foundation

/// Every outbound URL in one place, so none of them are buried in a view.
enum SupportLinks {
    /// Derived from the App Store Connect app ID, so these are already live.
    static let appStoreID = "6811720640"

    static let appStore = URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    static let writeReview = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!

    // TODO: replace with the real pages before shipping — these are placeholders
    // and currently point at the repository.
    static let privacy = URL(string: "https://github.com/iosipratama/bitcoin-tracker-ios")!
    static let terms = URL(string: "https://github.com/iosipratama/bitcoin-tracker-ios")!

    static let supportAddress = "support@mekarya.studio"

    /// Opens Mail with the subject filled in and the app and device details
    /// appended, so support reads a sortable inbox and doesn't have to reply
    /// asking which build this was.
    static var suggestFeature: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportAddress
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Sats Keeper Feature Request"),
            URLQueryItem(name: "body", value: SupportEnvironment.mailSignature)
        ]
        return components.url ?? URL(string: "mailto:\(supportAddress)")!
    }

    static let designer = URL(string: "https://mekarya.studio/")!

    static let blockExplorer = URL(string: "https://mempool.space")!
    static let priceData = URL(string: "https://www.coingecko.com")!
}
