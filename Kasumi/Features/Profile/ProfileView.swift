import SwiftUI

enum ProfileRoute: Hashable {
    case store, billing, settings
}

struct ProfileView: View {
    let app: AppModel
    @State private var viewModel: ProfileViewModel
    @State private var path: [ProfileRoute] = ProfileView.initialPath
    @State private var showPaywall = DemoScreen.current == .paywall
    @Environment(\.isWideLayout) private var isWide

    init(app: AppModel) {
        self.app = app
        _viewModel = State(initialValue: ProfileViewModel(app: app))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                Group {
                    if isWide {
                        // iPhone Duo inner display: who you are and your balance on the left,
                        // your videos and settings on the right.
                        HStack(alignment: .top, spacing: Theme.Space.xxl) {
                            VStack(spacing: Theme.Space.xl) {
                                header
                                balance
                                stats
                            }
                            .frame(width: 360)
                            VStack(spacing: Theme.Space.xl) {
                                recentVideos(columns: 4)
                                menu
                            }
                        }
                        .readableWidth(980)
                    } else {
                        VStack(spacing: Theme.Space.xl) {
                            header
                            balance
                            stats
                            recentVideos(columns: 4)
                            menu
                        }
                        .readableWidth()
                    }
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.top, Theme.Space.s)
                .padding(.bottom, Theme.Space.xxl)
            }
            .screenBackground()
            .navigationTitle("Profile")
            .adaptiveTitleDisplay(isWide)
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .store: StoreView(app: app)
                case .billing: BillingHistoryView(app: app)
                case .settings: SettingsView(app: app)
                }
            }
        }
        .task(id: app.generations.changeToken) { await viewModel.load() }
        .sheet(isPresented: $showPaywall) {
            PaywallView(app: app)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var header: some View {
        if let user = viewModel.user {
            HStack(spacing: Theme.Space.l) {
                Text(user.initials)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 64, height: 64)
                    .background(Theme.raised, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.hairline))
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(user.name)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    if let email = user.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    PlanTag(plan: user.plan)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// The one rich card on this screen: the balance and what it buys.
    @ViewBuilder
    private var balance: some View {
        if let user = viewModel.user {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text("Balance")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
                        Text("\(user.credits)")
                            .font(.system(size: 44, weight: .medium).monospacedDigit())
                            .foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText(value: Double(user.credits)))
                        Text("credits")
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text("Enough for about \(viewModel.videosLeft) videos with presets")
                        .font(.footnote)
                        .foregroundStyle(Theme.textMuted)
                }

                HStack(spacing: Theme.Space.s) {
                    if app.config.storeEnabled {
                        Button("Buy credits") { path.append(.store) }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    if user.plan == .free {
                        Button("Get Pro") { showPaywall = true }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
            .padding(Theme.Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
            .overlay(alignment: .topTrailing) {
                KasumiMark()
                    .fill(Theme.accent.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .padding(Theme.Space.l)
                    .accessibilityHidden(true)
            }
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous).strokeBorder(Theme.hairline))
            .animation(Theme.ease(0.3), value: user.credits)
        }
    }

    private var stats: some View {
        HStack(spacing: Theme.Space.m) {
            StatTile(title: "Videos", value: summary.map { "\($0.videoCount)" })
            StatTile(title: "Spent this month", value: summary.map { "\($0.spentThisMonth)" }, unit: "credits")
        }
    }

    private func recentVideos(columns: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title: "Recent videos")
                Button("See all") { app.selectedTab = .library }
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.s), count: columns),
                spacing: Theme.Space.s
            ) {
                if let summary {
                    ForEach(summary.recent) { generation in
                        Button {
                            app.openLibrary(generation)
                        } label: {
                            RemoteImage(url: generation.thumbnailURL)
                                .aspectRatio(3 / 4, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(generation.title)
                    }
                } else {
                    ForEach(0..<columns, id: \.self) { _ in
                        SkeletonBlock(cornerRadius: Theme.Radius.control)
                            .aspectRatio(3 / 4, contentMode: .fit)
                    }
                }
            }
        }
    }

    private var menu: some View {
        VStack(spacing: Theme.Space.l) {
            GroupedSection {
                NavigationRow(title: "Billing history") { path.append(.billing) }
                RowDivider()
                NavigationRow(title: "Settings") { path.append(.settings) }
            }
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
    }

    private var summary: ProfileViewModel.Summary? {
        if case .loaded(let summary) = viewModel.state { return summary }
        return nil
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

private struct PlanTag: View {
    let plan: User.Plan

    var body: some View {
        Text(plan == .pro ? "Kasumi Pro" : "Free plan")
            .font(.caption.weight(.medium))
            .foregroundStyle(plan == .pro ? Brand.onAccent : Theme.textSecondary)
            .padding(.horizontal, Theme.Space.s)
            .frame(height: 22)
            .background(plan == .pro ? Theme.accent : Theme.raised, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct StatTile: View {
    let title: String
    /// nil while loading.
    let value: String?
    var unit: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            if let value {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                    Text(value)
                        .font(.system(size: 24, weight: .medium).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                    if let unit {
                        Text(unit).font(.footnote).foregroundStyle(Theme.textMuted)
                    }
                }
            } else {
                SkeletonBlock(cornerRadius: 4).frame(width: 48, height: 24)
            }
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).strokeBorder(Theme.hairline))
        .accessibilityElement(children: .combine)
    }
}
