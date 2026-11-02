import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State {
        case loading
        case loaded(HomeScreen)
        case failed(String)
    }

    private(set) var state: State = .loading
    @ObservationIgnored private let app: AppModel
    @ObservationIgnored private var hasLoaded = false

    init(app: AppModel) {
        self.app = app
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        do {
            state = .loaded(try await app.backend.homeScreen())
            hasLoaded = true
        } catch {
            // Keep showing the last good layout on refresh failures.
            if case .loaded = state { return }
            state = .failed(error.localizedDescription)
            app.crashReporter.record(error, context: "home")
        }
    }

    func open(_ preset: Preset) {
        app.openCreate(with: preset)
    }
}
