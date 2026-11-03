import Foundation
import Observation
import StoreKit
import UIKit

enum AppTab: Hashable {
    case home, create, library, profile
}

/// App-wide state: session, balance, remote config and navigation between tabs.
/// Screens get their own ViewModels; this object only holds what several screens share.
@MainActor
@Observable
final class AppModel {
    enum AuthState {
        case loading, signedOut, signedIn
    }

    private(set) var authState: AuthState = .loading
    private(set) var user: User?
    private(set) var config = RemoteConfig()
    var selectedTab: AppTab = .home
    /// A preset picked on Home that the Create screen should preselect.
    var draftPreset: Preset?
    /// The credits store, opened from the balance in any toolbar.
    var isStorePresented = false
    /// A video the Library tab should open.
    var libraryFocus: Generation?
    private(set) var hasSeenOnboarding = UserDefaults.standard.bool(forKey: AppSettings.onboardingDoneKey)

    let backend: any Backend
    let analytics: any Analytics
    let crashReporter: any CrashReporter
    let generations: GenerationTracker

    @ObservationIgnored private let sessionStore = SessionStore()
    @ObservationIgnored private let notifications = NotificationService()
    @ObservationIgnored private var transactionUpdates: Task<Void, Never>?
    @ObservationIgnored private var didBootstrap = false
    @ObservationIgnored private var didAskForNotifications = false

    init(
        backend: any Backend,
        analytics: any Analytics = LogAnalytics(),
        crashReporter: any CrashReporter = LogCrashReporter()
    ) {
        self.backend = backend
        self.analytics = analytics
        self.crashReporter = crashReporter
        generations = GenerationTracker(backend: backend, analytics: analytics)
    }

    /// Swap `MockBackend()` for `LiveBackend(client: APIClient(baseURL: ...))` once the API is ready.
    static func live() -> AppModel {
        // The "ready" demo renders quickly so the screenshot shows a finished video.
        AppModel(backend: MockBackend(generationDuration: DemoScreen.current == .ready ? 3 : 20))
    }

    // MARK: - Lifecycle

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        observeTransactions()

        let backend = self.backend
        async let remoteConfig = try? backend.remoteConfig()

        if let demo = DemoScreen.current {
            await startDemo(demo)
        } else if let session = sessionStore.load() {
            user = session.user
            authState = .signedIn
            crashReporter.setUser(id: session.user.id)
            await refreshUser()
        } else {
            authState = .signedOut
        }

        if let remoteConfig = await remoteConfig {
            config = remoteConfig
        }
    }

    // MARK: - Session

    func signIn(_ provider: AuthProvider) async throws {
        let session = try await backend.signIn(with: provider)
        sessionStore.save(session)
        user = session.user
        authState = .signedIn
        crashReporter.setUser(id: session.user.id)
        analytics.track(.signedIn(method: provider.analyticsName))
    }

    func signOut() {
        sessionStore.clear()
        user = nil
        authState = .signedOut
        selectedTab = .home
        crashReporter.setUser(id: nil)
        analytics.track(.signedOut)
    }

    func finishOnboarding() {
        hasSeenOnboarding = true
        if DemoScreen.current == nil {
            UserDefaults.standard.set(true, forKey: AppSettings.onboardingDoneKey)
        }
    }

    func deleteAccount() async throws {
        try await backend.deleteAccount()
        analytics.track(.accountDeleted)
        signOut()
    }

    /// Live Activities need both the server flag and the user's setting.
    var liveActivitiesAllowed: Bool {
        config.liveActivitiesEnabled && AppSettings.liveActivities
    }

    func refreshUser() async {
        if let fresh = try? await backend.currentUser() {
            user = fresh
        }
    }

    func updateUser(_ user: User) {
        self.user = user
    }

    // MARK: - Navigation

    func openLibrary(_ generation: Generation) {
        libraryFocus = generation
        selectedTab = .library
    }

    func openCreate(with preset: Preset) {
        draftPreset = preset
        selectedTab = .create
    }

    // MARK: - Notifications

    /// Asked after the first generation, when the user understands why notifications help.
    func requestNotificationPermissionIfNeeded() async {
        guard DemoScreen.current == nil, !didAskForNotifications else { return }
        didAskForNotifications = true
        if await notifications.requestAuthorization() {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Purchases

    /// Handles purchases finished outside the purchase flow (renewals, Ask to Buy, interrupted purchases).
    private func observeTransactions() {
        transactionUpdates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                if let user = try? await self?.backend.redeemPurchase(
                    productID: transaction.productID,
                    transactionID: transaction.id
                ) {
                    self?.user = user
                }
                await transaction.finish()
            }
        }
    }

    // MARK: - Demo

    private func startDemo(_ screen: DemoScreen) async {
        guard screen != .auth, screen != .onboarding else {
            sessionStore.clear()
            hasSeenOnboarding = screen == .auth
            authState = .signedOut
            return
        }
        try? await signIn(.demo)
        selectedTab = screen.tab
    }
}
