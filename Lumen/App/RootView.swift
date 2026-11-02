import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Group {
            switch app.authState {
            case .loading:
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .signedOut:
                AuthView(app: app)
                    .transition(.opacity)
            case .signedIn:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: app.authState)
        .task { await app.bootstrap() }
    }
}

struct MainTabView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.selectedTab) {
            HomeView(app: app)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)
            CreateView(app: app)
                .tabItem { Label("Create", systemImage: "plus.square.fill") }
                .tag(AppTab.create)
            LibraryView(app: app)
                .tabItem { Label("Library", systemImage: "square.stack.fill") }
                .tag(AppTab.library)
            ProfileView(app: app)
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(AppTab.profile)
        }
    }
}
