import AVKit
import SwiftUI

struct GenerationDetailView: View {
    @State private var viewModel: GenerationDetailViewModel
    @State private var player: AVPlayer?
    @Environment(\.isWideLayout) private var isWide

    init(generation: Generation, app: AppModel) {
        _viewModel = State(initialValue: GenerationDetailViewModel(generation: generation, analytics: app.analytics))
    }

    private var generation: Generation { viewModel.generation }

    var body: some View {
        ScrollView {
            Group {
                if isWide {
                    HStack(alignment: .top, spacing: Theme.Space.xxl) {
                        video.frame(maxWidth: .infinity)
                        details(stacked: true).frame(width: 300)
                    }
                } else {
                    VStack(alignment: .leading, spacing: Theme.Space.xl) {
                        video
                        details(stacked: false)
                    }
                }
            }
            .padding(Theme.Space.l)
        }
        .screenBackground()
        .navigationTitle("")
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

    private var video: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
            } else {
                RemoteImage(url: generation.thumbnailURL)
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
    }

    /// Title and actions. On the wide layout the buttons stack in the side column.
    private func details(stacked: Bool) -> some View {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
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

                let actions = stacked
                    ? AnyLayout(VStackLayout(spacing: Theme.Space.m))
                    : AnyLayout(HStackLayout(spacing: Theme.Space.m))
                actions {
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
