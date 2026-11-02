import SwiftUI

struct HomeView: View {
    let app: AppModel
    @State private var viewModel: HomeViewModel

    init(app: AppModel) {
        self.app = app
        _viewModel = State(initialValue: HomeViewModel(app: app))
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            content
                .screenBackground()
                .navigationTitle("Kasumi")
                .creditsToolbar(app.user?.credits)
                .navigationDestination(for: Preset.self) { preset in
                    PresetDetailView(preset: preset) { viewModel.use(preset) }
                }
        }
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load presets", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { Task { await viewModel.load() } }
                    .buttonStyle(SecondaryButtonStyle(height: 40))
                    .frame(width: 160)
            }
        case .loaded(let screen):
            ScrollView {
                LazyVStack(spacing: Theme.Space.xxl) {
                    ForEach(screen.sections) { section in
                        HomeSectionView(section: section, onSelect: viewModel.open)
                    }
                }
                .padding(.top, Theme.Space.s)
                .padding(.bottom, Theme.Space.xxl)
            }
            .refreshable { await viewModel.load() }
        }
    }
}

/// Renders one server-driven section.
struct HomeSectionView: View {
    let section: HomeSection
    let onSelect: @MainActor (Preset) -> Void

    @Environment(\.isWideLayout) private var isWide

    /// Two columns on a phone, as many as fit on iPhone Duo's inner display.
    private var gridColumns: [GridItem] {
        if isWide {
            return [GridItem(.adaptive(minimum: 160), spacing: Theme.Space.m)]
        }
        return [GridItem(.flexible(), spacing: Theme.Space.m), GridItem(.flexible(), spacing: Theme.Space.m)]
    }

    var body: some View {
        switch section {
        case .hero(let hero):
            HeroCard(hero: hero, onSelect: onSelect)
                .padding(.horizontal, Theme.Space.l)

        case .carousel(let row):
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                SectionHeader(title: row.title).padding(.horizontal, Theme.Space.l)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Theme.Space.m) {
                        ForEach(row.items) { preset in
                            Button { onSelect(preset) } label: {
                                PresetCard(preset: preset).frame(width: 152, height: 216)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.Space.l)
                }
            }

        case .grid(let row):
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                SectionHeader(title: row.title)
                LazyVGrid(columns: gridColumns, spacing: Theme.Space.m) {
                    ForEach(row.items) { preset in
                        Button { onSelect(preset) } label: {
                            PresetCard(preset: preset).aspectRatio(3 / 4, contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.l)
        }
    }
}

/// The one rich moment on Home: a full-bleed image from the featured preset.
struct HeroCard: View {
    let hero: HomeSection.Hero
    let onSelect: @MainActor (Preset) -> Void
    @Environment(\.isWideLayout) private var isWide

    var body: some View {
        RemoteImage(url: hero.imageURL)
            .frame(height: isWide ? 320 : 280)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    if hero.preset?.tag != nil {
                        Text("New preset")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Text(hero.title)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                    Text(hero.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                    if let preset = hero.preset {
                        Button { onSelect(preset) } label: {
                            Text("See preset")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.background)
                                .padding(.horizontal, Theme.Space.l)
                                .frame(height: 36)
                                .background(Theme.textPrimary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, Theme.Space.s)
                    }
                }
                .padding(isWide ? Theme.Space.xl : Theme.Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ImageScrim())
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
            .onTapGesture {
                if let preset = hero.preset { onSelect(preset) }
            }
    }
}

struct PresetCard: View {
    let preset: Preset
    var showsDetails = true

    var body: some View {
        RemoteImage(url: preset.thumbnailURL)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    if showsDetails {
                        Text("\(preset.cost) credits")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(Theme.Space.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ImageScrim())
            }
            .overlay(alignment: .topLeading) {
                if showsDetails, preset.tag != nil {
                    Text("New")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(Theme.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .padding(Theme.Space.s)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}
