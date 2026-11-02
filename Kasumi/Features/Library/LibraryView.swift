import SwiftUI

struct LibraryView: View {
    let app: AppModel
    @State private var viewModel: LibraryViewModel

    @Environment(\.isWideLayout) private var isWide

    private var columns: [GridItem] {
        if isWide {
            return [GridItem(.adaptive(minimum: 170), spacing: Theme.Space.m)]
        }
        return [GridItem(.flexible(), spacing: Theme.Space.m), GridItem(.flexible(), spacing: Theme.Space.m)]
    }

    init(app: AppModel) {
        self.app = app
        _viewModel = State(initialValue: LibraryViewModel(app: app))
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            content
                .screenBackground()
                .navigationTitle("Library")
                .creditsToolbar(app.user?.credits)
                .navigationDestination(for: Generation.self) { generation in
                    GenerationDetailView(generation: generation, app: app)
                }
        }
        // Reload when a generation starts or finishes.
        .task(id: app.generations.changeToken) { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load your library", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { Task { await viewModel.load() } }
                    .buttonStyle(SecondaryButtonStyle(height: 40))
                    .frame(width: 160)
            }
        case .loaded(let items) where items.isEmpty:
            ContentUnavailableView {
                Label("No videos yet", systemImage: "film.stack")
            } description: {
                Text("Videos you generate will appear here")
            } actions: {
                Button("Create a video") { app.selectedTab = .create }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(width: 200)
            }
        case .loaded(let items):
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Space.m) {
                    ForEach(items) { item in
                        let generation = app.generations.latest(item)
                        if generation.status == .completed {
                            NavigationLink(value: generation) {
                                GenerationCell(generation: generation)
                            }
                            .buttonStyle(.plain)
                        } else {
                            GenerationCell(generation: generation)
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.vertical, Theme.Space.s)
            }
            .refreshable { await viewModel.load() }
        }
    }
}

struct GenerationCell: View {
    let generation: Generation

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            RemoteImage(url: generation.thumbnailURL)
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    if !generation.isFinished {
                        ZStack {
                            Theme.background.opacity(0.7)
                            ProgressRing(progress: generation.progress)
                                .frame(width: 40, height: 40)
                        }
                    } else if generation.status == .failed {
                        ZStack {
                            Theme.background.opacity(0.7)
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(Theme.negative)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(generation.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        switch generation.status {
        case .completed: generation.createdAt.formatted(.relative(presentation: .named))
        case .failed: "Failed"
        case .queued, .processing: "\(generation.status.label) · \(Int(generation.progress * 100))%"
        }
    }
}
