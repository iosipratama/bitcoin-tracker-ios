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
                Text("Recent activity")
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
        VStack(spacing: 0) {
            ForEach(items) { item in
                ActivityRow(item: item, viewModel: viewModel)
            }
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
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
                RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
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
            RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                .fill(.groupedBackground)
        )
    }

    private static let placeholders = (0..<3).map {
        ActivityItem(id: "placeholder-\($0)", netSatoshis: 1_000_000, date: .now)
    }
}

private struct ActivityRow: View {
    let item: ActivityItem
    let viewModel: PortfolioViewModel

    @Environment(\.openURL) private var openURL

    private var title: String { item.isReceived ? "Received" : "Sent" }

    private var dateText: String {
        item.date?.formatted(date: .abbreviated, time: .omitted) ?? "Pending"
    }

    var body: some View {
        Button {
            if let url = item.explorerURL { openURL(url) }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(.cardInsetBackground)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: item.isReceived ? "arrow.down" : "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(item.isReceived ? AnyShapeStyle(.brand) : AnyShapeStyle(.secondaryLabel))
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.label)

                    Text(dateText)
                        .font(.system(size: 13))
                        .foregroundStyle(item.isPending ? AnyShapeStyle(.brand) : AnyShapeStyle(.tertiaryLabel))
                }

                Spacer(minLength: 8)

                Text(viewModel.formattedActivity(item.netSatoshis))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(item.isReceived ? AnyShapeStyle(.label) : AnyShapeStyle(.secondaryLabel))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(viewModel.formattedActivity(item.netSatoshis)), \(dateText)")
        .accessibilityHint("Opens the transaction on mempool.space")
    }
}
