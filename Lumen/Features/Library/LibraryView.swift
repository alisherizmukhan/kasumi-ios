import SwiftUI

struct LibraryView: View {
    let app: AppModel
    @State private var viewModel: LibraryViewModel

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(app: AppModel) {
        self.app = app
        _viewModel = State(initialValue: LibraryViewModel(app: app))
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            content
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
                    .buttonStyle(.borderedProminent)
            }
        case .loaded(let items) where items.isEmpty:
            ContentUnavailableView {
                Label("No videos yet", systemImage: "sparkles.rectangle.stack")
            } description: {
                Text("Your generations will appear here.")
            } actions: {
                Button("Create your first video") { app.selectedTab = .create }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded(let items):
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
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
                .padding()
            }
            .refreshable { await viewModel.load() }
        }
    }
}

struct GenerationCell: View {
    let generation: Generation

    var body: some View {
        RemoteImage(url: generation.thumbnailURL)
            .aspectRatio(3 / 4, contentMode: .fit)
            .overlay {
                if !generation.isFinished {
                    ZStack {
                        Color.black.opacity(0.55)
                        VStack(spacing: 10) {
                            ProgressView(value: generation.progress)
                                .tint(Theme.accent)
                                .padding(.horizontal, 20)
                            Text("\(generation.status.label) · \(Int(generation.progress * 100))%")
                                .font(.caption.weight(.medium).monospacedDigit())
                        }
                    }
                } else if generation.status == .failed {
                    ZStack {
                        Color.black.opacity(0.55)
                        Label("Failed", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            .overlay(alignment: .bottomLeading) {
                if generation.status == .completed {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill").font(.caption2)
                        Text(generation.title).font(.caption.weight(.semibold)).lineLimit(1)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}
