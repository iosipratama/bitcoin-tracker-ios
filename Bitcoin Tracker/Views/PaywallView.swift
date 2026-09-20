import SwiftUI

/// The one place the app asks for money. Shown when a third wallet is added,
/// and from Settings once there is something to restore.
struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                eyebrow
                headline
                terms
            }
            .padding(.horizontal, 50)
            .padding(.top, 72)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .top) { closeBar }
        .safeAreaInset(edge: .bottom) { purchaseBar }
        .background(Custom.backgroundBase)
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }

    private var closeBar: some View {
        HStack {
            Spacer()
            SheetCloseButton { dismiss() }
        }
        .padding(.horizontal, 16)
    }

    private var eyebrow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Custom.accent)
                .frame(width: 12, height: 12)

            Text("Sato Plus")
                .font(.system(size: 12, weight: .semibold))
                .tracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(Custom.labelSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Own the app.")
                .foregroundStyle(Custom.labelPrimary)

            Text("Add as many wallets as you like.")
                .foregroundStyle(Custom.labelTertiary)
        }
        .font(.system(size: 48, weight: .medium))
        .fontDesign(.rounded)
        .tracking(-1.03)
        .lineSpacing(-4)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var terms: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.priceLine)
                .font(.system(size: 20, weight: .light))
                .tracking(0.34)
                .foregroundStyle(Custom.labelPrimary)
                .opacity(0.8)

            Text("Thanks for the support 🫶")
                .font(.system(size: 14))
                .foregroundStyle(Custom.labelTertiary)

            if let message = store.message {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.negative)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // The product is absent whenever the App Store can't be reached —
            // which is always, in the simulator — so this state says so rather
            // than leaving a dead button and no explanation.
            if store.product == nil {
                HStack(spacing: 8) {
                    Text("Can’t reach the App Store.")

                    Button("Try again") {
                        Task { await store.loadProduct() }
                    }
                    .foregroundStyle(.brand)
                }
                .font(.system(size: 14))
                .foregroundStyle(Custom.labelTertiary)
                .buttonStyle(.plain)
            }
        }
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var purchaseBar: some View {
        VStack(spacing: 24) {
            ProminentCapsuleButton(
                title: store.isPurchasing ? "Purchasing" : "Continue",
                isBusy: store.isPurchasing,
                isEnabled: store.canPurchase
            ) {
                Task { await store.purchase() }
            }

            footerLinks
        }
        .padding(.bottom, 24)
    }

    private var footerLinks: some View {
        HStack(spacing: 32) {
            Button("Terms") { openURL(SupportLinks.terms) }
            Button("Privacy") { openURL(SupportLinks.privacy) }
            Button("Restore") { Task { await store.restore() } }
                .disabled(store.isRestoring)
        }
        .font(.system(size: 14, weight: .medium))
        .fontDesign(.rounded)
        .tracking(-0.31)
        .foregroundStyle(Custom.labelSecondary)
        .opacity(0.3)
        .buttonStyle(.plain)
    }
}
