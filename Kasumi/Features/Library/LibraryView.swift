import SwiftUI
import UIKit

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
                .creditsToolbar(app)
                .adaptiveTitleDisplay(isWide)
                .navigationDestination(for: Generation.self) { generation in
                    GenerationDetailView(generation: generation, app: app)
                }
        }
        // Reload when a generation starts or finishes.
        .task(id: app.generations.changeToken) { await viewModel.load() }
        // Opened from a "Ready" card on the Create tab.
        .task(id: app.libraryFocus) {
            guard let generation = app.libraryFocus else { return }
            viewModel.path = [generation]
            app.libraryFocus = nil
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LibrarySkeleton(columns: columns)
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
                            GenerationCell(generation: generation, sourceImage: app.generations.sourceImages[item.id])
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
    /// The photo a rendering video started from, shown under its progress.
    var sourceImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Group {
                if let sourceImage, generation.thumbnailURL == nil {
                    Color.clear.overlay {
                        Image(uiImage: sourceImage).resizable().scaledToFill()
                    }
                    .clipped()
                } else {
                    RemoteImage(url: generation.thumbnailURL)
                }
            }
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    if !generation.isFinished {
                        ZStack {
                            Theme.background.opacity(0.55)
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
