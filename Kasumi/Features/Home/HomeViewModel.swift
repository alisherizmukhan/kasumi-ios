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
    var path: [Preset] = []
    @ObservationIgnored private let app: AppModel
    @ObservationIgnored private var hasLoaded = false

    init(app: AppModel) {
        self.app = app
    }

    func loadIfNeeded() async {
        // The loading demo stays on the skeleton so it can be photographed.
        guard !hasLoaded, DemoScreen.current != .homeLoading else { return }
        await load()
    }

    func load() async {
        do {
            let screen = try await app.backend.homeScreen()
            state = .loaded(screen)
            hasLoaded = true
            if DemoScreen.current == .preset, path.isEmpty, let first = screen.allPresets.first {
                path = [first]
            }
        } catch {
            // Keep showing the last good layout on refresh failures.
            if case .loaded = state { return }
            state = .failed(error.localizedDescription)
            app.crashReporter.record(error, context: "home")
        }
    }

    /// Opens the preset's page.
    func open(_ preset: Preset) {
        path.append(preset)
        app.analytics.track(.presetOpened(id: preset.id))
    }

    /// Sends the preset to the Create tab.
    func use(_ preset: Preset) {
        app.openCreate(with: preset)
        path.removeAll()
    }
}
