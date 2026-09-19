import Foundation
import StoreKit

/// The app's one purchase: a non-consumable that lifts the wallet limit.
@Observable
@MainActor
final class StoreManager {
    static let productID = "com.iosipratama.BitcoinTracker.plus"

    private enum Key {
        #if DEBUG
        static let forcesPaywall = "debugForcesPaywall"
        static let fakesUnlock = "debugFakesUnlock"
        #endif
    }

    private(set) var product: Product?
    private(set) var hasEntitlement = false
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    private(set) var isAwaitingApproval = false
    private(set) var message: String?

    /// Held for the process. Deliberately never cancelled: `deinit` is
    /// nonisolated and couldn't touch this, and there is only ever one store.
    private var updates: Task<Void, Never>?

    #if DEBUG
    var forcesPaywall: Bool {
        didSet {
            guard forcesPaywall != oldValue else { return }
            UserDefaults.standard.set(forcesPaywall, forKey: Key.forcesPaywall)
        }
    }

    var fakesUnlock: Bool {
        didSet {
            guard fakesUnlock != oldValue else { return }
            UserDefaults.standard.set(fakesUnlock, forKey: Key.fakesUnlock)
        }
    }
    #endif

    init() {
        #if DEBUG
        let defaults = UserDefaults.standard
        forcesPaywall = defaults.bool(forKey: Key.forcesPaywall)
        fakesUnlock = defaults.bool(forKey: Key.fakesUnlock)
        #endif

        // Started at launch rather than when the paywall opens: a purchase
        // approved elsewhere — Ask to Buy, or a retried payment — arrives
        // whenever it lands, not only while someone is watching.
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }

                // Both cases are finished. An unfinished transaction is
                // redelivered on every launch, forever.
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                case .unverified(let transaction, _):
                    await transaction.finish()
                }

                self.apply(result)
            }
        }
    }

    /// The one question the rest of the app asks.
    var isUnlocked: Bool {
        #if DEBUG
        // Wins over a real entitlement, so the paywall stays reachable after a
        // sandbox purchase.
        if forcesPaywall { return false }
        if fakesUnlock { return true }
        #endif
        return hasEntitlement
    }

    func canAddWallet(existing: Int) -> Bool {
        isUnlocked || existing < Wallet.freeLimit
    }

    var canPurchase: Bool {
        product != nil && !isPurchasing && !isRestoring
    }

    /// Never a hardcoded price. Apple's tiers aren't a currency conversion —
    /// the 9.99 USD tier is ¥1,500 in Japan — so a literal would be wrong in
    /// most storefronts. With no product there is no price to quote.
    var priceLine: String {
        if let product {
            "\(product.displayPrice) · pay once,\nno subscription, ever."
        } else {
            "Pay once, no subscription, ever."
        }
    }

    // MARK: - Launch

    func load() async {
        await refreshEntitlement()
        await loadProduct()
    }

    func loadProduct() async {
        message = nil

        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            product = nil
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product, !isPurchasing else { return }

        isPurchasing = true
        message = nil
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    apply(verification)
                } else if case .unverified(let transaction, _) = verification {
                    await transaction.finish()
                    message = "That purchase couldn’t be verified with the App Store."
                }

            case .pending:
                // Ask to Buy, or a bank-side approval. It arrives later on
                // Transaction.updates, which is why that listener exists.
                isAwaitingApproval = true
                message = "Waiting for approval. This unlocks as soon as it goes through."

            case .userCancelled:
                break

            @unknown default:
                break
            }
        } catch StoreKitError.userCancelled {
            // Not a failure, and not worth a message.
        } catch StoreKitError.networkError {
            message = "Couldn’t reach the App Store. Check your connection and try again."
        } catch {
            message = "The purchase didn’t go through."
        }
    }

    // MARK: - Restore

    func restore() async {
        guard !isRestoring else { return }

        isRestoring = true
        message = nil
        defer { isRestoring = false }

        // Silent re-read first. If the entitlement is already on the device
        // this unlocks without making anyone authenticate; AppStore.sync()
        // raises a sign-in prompt and is only needed on a new device.
        await refreshEntitlement()
        guard !isUnlocked else { return }

        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isUnlocked {
                message = "No purchase to restore on this Apple Account."
            }
        } catch StoreKitError.userCancelled {
            // Backed out of the sign-in sheet.
        } catch {
            message = "Couldn’t reach the App Store. Check your connection and try again."
        }
    }

    // MARK: - Entitlement

    private func refreshEntitlement() async {
        guard let result = await Transaction.currentEntitlement(for: Self.productID) else {
            // Deliberately does not clear the unlock. An empty read is
            // ambiguous — never bought, and can't reach the App Store, look
            // identical — and locking out someone who paid is the worse of
            // the two mistakes. Revocation arrives explicitly, below.
            return
        }

        apply(result)
    }

    private func apply(_ result: VerificationResult<Transaction>) {
        guard case .verified(let transaction) = result,
              transaction.productID == Self.productID
        else { return }

        // The only thing that ever takes the unlock away: a refund or a
        // family-sharing removal, signed by Apple.
        hasEntitlement = transaction.revocationDate == nil

        if hasEntitlement {
            isAwaitingApproval = false
            message = nil
        }
    }
}
