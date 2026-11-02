import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Group {
            switch app.authState {
            case .loading:
                KasumiMark()
                    .fill(Theme.accent)
                    .frame(width: 64, height: 64)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .signedOut where !app.hasSeenOnboarding:
                OnboardingView { app.finishOnboarding() }
                    .transition(.opacity)
            case .signedOut:
                AuthView(app: app)
                    .transition(.opacity)
            case .signedIn:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(Theme.ease(0.3), value: app.authState)
        .animation(Theme.ease(0.3), value: app.hasSeenOnboarding)
        .task { await app.bootstrap() }
    }
}

/// On iPhone the tabs sit at the bottom. On iPhone Duo's inner display, which reports a
/// regular width, iOS 18+ draws the same TabView as a compact bar at the top, like on iPad.
struct MainTabView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.selectedTab) {
            HomeView(app: app)
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)
            CreateView(app: app)
                .tabItem { Label("Create", systemImage: "plus.square") }
                .tag(AppTab.create)
            LibraryView(app: app)
                .tabItem { Label("Library", systemImage: "film.stack") }
                .tag(AppTab.library)
            ProfileView(app: app)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
    }
}
