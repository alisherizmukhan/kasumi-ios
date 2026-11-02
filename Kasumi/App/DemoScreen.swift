import Foundation

/// Opens the app on a specific screen with demo data: `-demoScreen create`.
/// CI uses it to capture screenshots of every screen on iPhone and iPhone Duo.
enum DemoScreen: String, CaseIterable {
    case onboarding, auth
    case home, preset, create, library, detail
    case profile, store, purchased, paywall, billing, settings

    static var current: DemoScreen? {
        UserDefaults.standard.string(forKey: "demoScreen").flatMap(DemoScreen.init(rawValue:))
    }

    var tab: AppTab {
        switch self {
        case .onboarding, .auth, .home, .preset: .home
        case .create: .create
        case .library, .detail: .library
        case .profile, .store, .purchased, .paywall, .billing, .settings: .profile
        }
    }
}
