import SwiftUI

struct HomeView: View {
    let app: AppModel
    @State private var viewModel: HomeViewModel

    init(app: AppModel) {
        self.app = app
        _viewModel = State(initialValue: HomeViewModel(app: app))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Lumen")
                .creditsToolbar(app.user?.credits)
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
                Label("Couldn't load", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded(let screen):
            ScrollView {
                LazyVStack(spacing: 28) {
                    ForEach(screen.sections) { section in
                        HomeSectionView(section: section, onSelect: viewModel.open)
                    }
                }
                .padding(.vertical, 8)
            }
            .refreshable { await viewModel.load() }
        }
    }
}

/// Renders one server-driven section.
struct HomeSectionView: View {
    let section: HomeSection
    let onSelect: @MainActor (Preset) -> Void

    private let gridColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        switch section {
        case .hero(let hero):
            HeroCard(hero: hero, onSelect: onSelect)
                .padding(.horizontal)

        case .carousel(let row):
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: row.title).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(row.items) { preset in
                            Button { onSelect(preset) } label: {
                                PresetCard(preset: preset).frame(width: 150, height: 220)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }

        case .grid(let row):
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: row.title)
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(row.items) { preset in
                        Button { onSelect(preset) } label: {
                            PresetCard(preset: preset).aspectRatio(3 / 4, contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HeroCard: View {
    let hero: HomeSection.Hero
    let onSelect: @MainActor (Preset) -> Void

    var body: some View {
        RemoteImage(url: hero.imageURL)
            .frame(height: 260)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(hero.title).font(.title.bold())
                    Text(hero.subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.85))
                    if let preset = hero.preset {
                        Button { onSelect(preset) } label: {
                            Label("Try it", systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.white, in: Capsule())
                                .foregroundStyle(.black)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct PresetCard: View {
    let preset: Preset

    var body: some View {
        RemoteImage(url: preset.thumbnailURL)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Label("\(preset.cost)", systemImage: "bolt.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom))
            }
            .overlay(alignment: .topLeading) {
                if let tag = preset.tag {
                    Text(tag.uppercased())
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.gradient, in: Capsule())
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}
