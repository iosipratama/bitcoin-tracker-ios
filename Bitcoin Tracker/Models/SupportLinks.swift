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

    /// Opens Mail with the subject already filled in, so support reads a
    /// sortable inbox rather than a pile of untitled mail.
    static let suggestFeature = URL(string: "mailto:support@mekarya.studio?subject=Sats%20Keeper%20Feature%20Request")!

    static let designer = URL(string: "https://mekarya.studio/")!

    static let blockExplorer = URL(string: "https://mempool.space")!
    static let priceData = URL(string: "https://www.coingecko.com")!
}
