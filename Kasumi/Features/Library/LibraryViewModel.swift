import Foundation
import Observation

@MainActor
@Observable
final class LibraryViewModel {
    enum State {
        case loading
        case loaded([Generation])
        case failed(String)
    }

    private(set) var state: State = .loading
    var path: [Generation] = []

    @ObservationIgnored private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    func load() async {
        do {
            let items = try await app.backend.library()
            state = .loaded(items)
            if DemoScreen.current == .detail, path.isEmpty, let first = items.first(where: { $0.status == .completed }) {
                path = [first]
            }
        } catch {
            if case .loaded = state { return }
            state = .failed(error.localizedDescription)
            app.crashReporter.record(error, context: "library")
        }
    }
}
