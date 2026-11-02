import Foundation

/// Opens the app on a specific screen with demo data: `-demoScreen create`.
/// CI uses it to capture screenshots of every screen.
enum DemoScreen: String {
    case auth, home, create, library, detail, profile, store

    static var current: DemoScreen? {
        UserDefaults.standard.string(forKey: "demoScreen").flatMap(DemoScreen.init(rawValue:))
    }

    var tab: AppTab {
        switch self {
        case .auth, .home: .home
        case .create: .create
        case .library, .detail: .library
        case .profile, .store: .profile
        }
    }
}
