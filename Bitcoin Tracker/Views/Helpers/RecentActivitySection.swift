import SwiftUI

/// The last few transactions in and out of a wallet. Shown from what's stored
/// first and refreshed underneath, so a slow network changes nothing on screen
/// until there is something new to say.
struct RecentActivitySection: View {
    let wallet: Wallet

    @Environment(ActivityStore.self) private var activity
    @Environment(PortfolioViewModel.self) private var viewModel

    var body: some View {
        let entry = activity.entry(for: wallet)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent Activity")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondaryLabel)

                Spacer()

                if let entry {
                    StaleStamp(updated: entry.updated, didFail: activity.didFail(wallet))
                }
            }
            .padding(.horizontal, 20)

            Group {
                if let entry {
                    if entry.items.isEmpty {
                        message("No transactions yet")
                    } else {
                        list(entry.items)
                    }
                } else if activity.didFail(wallet) && !activity.isLoading(wallet) {
                    unavailable
                } else {
                    list(Self.placeholders)
                        .redacted(reason: .placeholder)
                        .accessibilityLabel("Loading recent activity")
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 24)
        .animation(.smooth, value: entry?.items)
    }

    private func list(_ items: [ActivityItem]) -> some View {
        VStack(spacing: 16) {
            ForEach(items) { item in
                ActivityRow(item: item, viewModel: viewModel)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: .cardInsetRadius, style: .continuous)
                .fill(.groupedBackground)
        )
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(.tertiaryLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: .cardInsetRadius, style: .continuous)
                    .fill(.groupedBackground)
            )
    }

    private var unavailable: some View {
        VStack(spacing: 12) {
            Text("Couldn’t load activity right now.")
                .font(.system(size: 15))
                .foregroundStyle(.tertiaryLabel)

            Button("Try Again") {
                Task { await activity.refresh(wallet, force: true) }
            }
            .font(.system(size: 15, weight: .semibold))
            .tint(.brand)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: .cardInsetRadius, style: .continuous)
                .fill(.groupedBackground)
        )
    }

    private static let placeholders = (0..<3).map {
        ActivityItem(id: "placeholder-\($0)", netSatoshis: 1_000_000, date: .now, counterparty: "bc1qplaceholderaddress")
    }
}

/// Dated rather than iconed: the date leads, the second line says which way
/// the coins went and with whom, and the sign on the amount says the rest.
private struct ActivityRow: View {
    let item: ActivityItem
    let viewModel: PortfolioViewModel

    private var dateText: String {
        item.date?.formatted(.dateTime.day().month(.abbreviated).year()) ?? "Pending"
    }

    private var btc: Double { Double(item.netSatoshis.magnitude) / .satoshisPerBTC }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateText)
                    .foregroundStyle(item.isPending ? AnyShapeStyle(.brand) : AnyShapeStyle(.label))

                Text(item.counterpartyLine)
                    .fontWeight(.medium)
                    .foregroundStyle(Custom.labelTertiary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 2) {
                // A true minus, so it holds the same width as the plus.
                Text(item.isReceived ? "+" : "\u{2212}")

                if let prefix = viewModel.amountPrefix {
                    Text(prefix)
                }

                Text(viewModel.formattedAmount(btc: btc))

                if let suffix = viewModel.amountSuffix {
                    Text(suffix)
                }
            }
            .foregroundStyle(.label)
            .minimumScaleFactor(0.6)
        }
        .font(.system(size: 15, weight: .semibold))
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.isReceived ? "Received" : "Sent") \(viewModel.formattedBTC(btc)), \(item.counterpartyLine), \(dateText)")
    }
}
