import SwiftUI

enum ProfileRoute: Hashable {
    case store, billing, settings
}

struct ProfileView: View {
    let app: AppModel
    @State private var path: [ProfileRoute] = ProfileView.initialPath
    @State private var showPaywall = DemoScreen.current == .paywall
    @Environment(\.isWideLayout) private var isWide

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                Group {
                    if isWide {
                        HStack(alignment: .top, spacing: Theme.Space.xl) {
                            VStack(spacing: Theme.Space.xl) {
                                account
                                balance
                            }
                            VStack(spacing: Theme.Space.xl) {
                                more
                                remoteConfig
                                signOut
                            }
                        }
                        .readableWidth(920)
                    } else {
                        VStack(spacing: Theme.Space.xl) {
                            account
                            balance
                            more
                            remoteConfig
                            signOut
                        }
                        .readableWidth()
                    }
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.vertical, Theme.Space.s)
            }
            .screenBackground()
            .navigationTitle("Profile")
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .store: StoreView(app: app)
                case .billing: BillingHistoryView(app: app)
                case .settings: SettingsView(app: app)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(app: app)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var account: some View {
        if let user = app.user {
            GroupedSection {
                HStack(spacing: Theme.Space.m) {
                    Text(user.initials)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(Theme.raised, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.hairline))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)
                        if let email = user.email {
                            Text(email)
                                .font(.footnote)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(Theme.Space.l)
            }
        }
    }

    @ViewBuilder
    private var balance: some View {
        if let user = app.user {
            GroupedSection(header: "Balance") {
                ValueRow(title: "Credits", value: "\(user.credits)", mono: true)
                RowDivider()
                if user.plan == .pro {
                    ValueRow(title: "Plan", value: "Kasumi Pro")
                } else {
                    NavigationRow(title: "Plan", value: "Free · Upgrade") { showPaywall = true }
                }
                if app.config.storeEnabled {
                    RowDivider()
                    NavigationRow(title: "Buy credits") { path.append(.store) }
                }
            }
        }
    }

    private var more: some View {
        GroupedSection(header: "Account") {
            NavigationRow(title: "Billing history") { path.append(.billing) }
            RowDivider()
            NavigationRow(title: "Settings") { path.append(.settings) }
        }
    }

    private var remoteConfig: some View {
        GroupedSection(
            header: "Remote config",
            footer: "Feature flags come from the server and change without an app update"
        ) {
            ValueRow(title: "Live Activities", value: app.config.liveActivitiesEnabled ? "On" : "Off")
            RowDivider()
            ValueRow(title: "Store", value: app.config.storeEnabled ? "On" : "Off")
            RowDivider()
            ValueRow(title: "Max prompt length", value: "\(app.config.maxPromptLength)", mono: true)
        }
    }

    private var signOut: some View {
        GroupedSection {
            Button {
                app.signOut()
            } label: {
                Text("Sign out")
                    .foregroundStyle(Theme.negative)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .padding(.horizontal, Theme.Space.l)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private static var initialPath: [ProfileRoute] {
        switch DemoScreen.current {
        case .store, .purchased: [.store]
        case .billing: [.billing]
        case .settings: [.settings]
        default: []
        }
    }
}
