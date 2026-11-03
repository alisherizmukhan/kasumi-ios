import Foundation
import Observation

/// Loads what the profile shows besides the account itself: recent videos and this month's activity.
@MainActor
@Observable
final class ProfileViewModel {
    struct Summary {
        let videoCount: Int
        let spentThisMonth: Int
        let recent: [Generation]
    }

    enum State {
        case loading
        case loaded(Summary)
        case failed(String)
    }

    private(set) var state: State = .loading
    @ObservationIgnored private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    var user: User? { app.user }

    /// Typical preset cost, used for "enough for about N videos".
    private static let typicalCost = 15

    var videosLeft: Int {
        (app.user?.credits ?? 0) / Self.typicalCost
    }

    func load() async {
        let backend = app.backend
        do {
            async let library = backend.library()
            async let billing = backend.billingHistory()
            let (videos, entries) = try await (library, billing)
            state = .loaded(Self.summarize(videos: videos, billing: entries))
        } catch {
            if case .loaded = state { return }
            state = .failed(error.localizedDescription)
        }
    }

    static func summarize(videos: [Generation], billing: [BillingEntry], now: Date = .now, calendar: Calendar = .current) -> Summary {
        let spent = billing
            .filter { $0.credits < 0 && calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 - $1.credits }
        let finished = videos.filter { $0.status == .completed }
        return Summary(videoCount: finished.count, spentThisMonth: spent, recent: Array(finished.prefix(4)))
    }
}
