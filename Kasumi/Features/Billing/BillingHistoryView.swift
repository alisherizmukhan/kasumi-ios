import Observation
import SwiftUI

@MainActor
@Observable
final class BillingHistoryViewModel {
    struct Month: Identifiable {
        let id: String
        let title: String
        let entries: [BillingEntry]
    }

    enum State {
        case loading
        case loaded([Month])
        case failed(String)
    }

    private(set) var state: State = .loading
    @ObservationIgnored private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    func load() async {
        do {
            let entries = try await app.backend.billingHistory()
            state = .loaded(Self.groupByMonth(entries))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Groups entries (already newest first) into calendar months.
    static func groupByMonth(_ entries: [BillingEntry], calendar: Calendar = .current) -> [Month] {
        var months: [Month] = []
        for entry in entries {
            let parts = calendar.dateComponents([.year, .month], from: entry.date)
            let id = "\(parts.year ?? 0)-\(parts.month ?? 0)"
            if let last = months.last, last.id == id {
                months[months.count - 1] = Month(id: id, title: last.title, entries: last.entries + [entry])
            } else {
                let title = entry.date.formatted(.dateTime.month(.wide).year())
                months.append(Month(id: id, title: title, entries: [entry]))
            }
        }
        return months
    }
}

struct BillingHistoryView: View {
    @State private var viewModel: BillingHistoryViewModel

    init(app: AppModel) {
        _viewModel = State(initialValue: BillingHistoryViewModel(app: app))
    }

    var body: some View {
        content
            .screenBackground()
            .navigationTitle("Billing history")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView("Couldn't load billing history", systemImage: "wifi.exclamationmark", description: Text(message))
        case .loaded(let months) where months.isEmpty:
            ContentUnavailableView("No payments yet", systemImage: "creditcard", description: Text("Purchases and credits you spend will appear here"))
        case .loaded(let months):
            ScrollView {
                VStack(spacing: Theme.Space.xl) {
                    ForEach(months) { month in
                        GroupedSection(header: month.title) {
                            ForEach(Array(month.entries.enumerated()), id: \.element.id) { index, entry in
                                if index > 0 { RowDivider() }
                                BillingRow(entry: entry)
                            }
                        }
                    }
                }
                .readableWidth()
                .padding(.horizontal, Theme.Space.l)
                .padding(.vertical, Theme.Space.s)
            }
        }
    }
}

private struct BillingRow: View {
    let entry: BillingEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title).foregroundStyle(Theme.textPrimary)
                Text(caption)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(entry.credits > 0 ? Brand.positive : Theme.textSecondary)
                if let price = entry.price {
                    Text(price)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .padding(.horizontal, Theme.Space.l)
        .padding(.vertical, Theme.Space.m)
        .accessibilityElement(children: .combine)
    }

    private var amount: String {
        entry.credits > 0 ? "+\(entry.credits)" : "\u{2212}\(abs(entry.credits))"
    }

    private var caption: String {
        let date = entry.date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
        switch entry.kind {
        case .purchase: return "Credit pack · \(date)"
        case .subscription: return "Subscription · \(date)"
        case .generation: return "Video · \(date)"
        case .bonus: return "Bonus · \(date)"
        case .refund: return "Refund · \(date)"
        }
    }
}
