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
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                ZStack {
                    if let player {
                        VideoPlayer(player: player)
                    } else {
                        RemoteImage(url: generation.thumbnailURL)
                    }
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))

                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Text(generation.title)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    if !generation.prompt.isEmpty {
                        Text(generation.prompt)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text(generation.createdAt, format: .dateTime.day().month().hour().minute())
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.textMuted)
                }

                HStack(spacing: Theme.Space.m) {
                    Button {
                        Task { await viewModel.saveToPhotos() }
                    } label: {
                        saveLabel
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(viewModel.saveState == .saving || viewModel.saveState == .saved)

                    if let url = generation.videoURL {
                        ShareLink(item: url) {
                            Text("Share")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }

                if case .failed(let message) = viewModel.saveState {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Theme.negative)
                }
            }
            .padding(Theme.Space.l)
        }
        .screenBackground()
        .navigationTitle(generation.title)
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
        case .idle: Text("Save to Photos")
        case .saving: ProgressView()
        case .saved: Text("Saved")
        case .failed: Text("Try again")
        }
    }
}
