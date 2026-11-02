import AVKit
import SwiftUI

struct GenerationDetailView: View {
    @State private var viewModel: GenerationDetailViewModel
    @State private var player: AVPlayer?

    init(generation: Generation, app: AppModel) {
        _viewModel = State(initialValue: GenerationDetailViewModel(generation: generation, analytics: app.analytics))
    }

    private var generation: Generation { viewModel.generation }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack {
                    if let player {
                        VideoPlayer(player: player)
                    } else {
                        RemoteImage(url: generation.thumbnailURL)
                    }
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(generation.title)
                        .font(.title2.bold())
                    if !generation.prompt.isEmpty {
                        Text(generation.prompt)
                            .foregroundStyle(.secondary)
                    }
                    Text(generation.createdAt, format: .dateTime.day().month().hour().minute())
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.saveToPhotos() }
                    } label: {
                        saveLabel.frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(viewModel.saveState == .saving || viewModel.saveState == .saved)

                    if let url = generation.videoURL {
                        ShareLink(item: url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }

                if case .failed(let message) = viewModel.saveState {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Video")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard player == nil, let url = generation.videoURL else { return }
            let newPlayer = AVPlayer(url: url)
            newPlayer.isMuted = DemoScreen.current != nil
            newPlayer.play()
            player = newPlayer
        }
        .onDisappear { player?.pause() }
    }

    @ViewBuilder
    private var saveLabel: some View {
        switch viewModel.saveState {
        case .idle: Label("Save", systemImage: "arrow.down.to.line")
        case .saving: ProgressView()
        case .saved: Label("Saved", systemImage: "checkmark")
        case .failed: Label("Retry", systemImage: "arrow.clockwise")
        }
    }
}
