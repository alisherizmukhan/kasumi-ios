import AVKit
import SwiftUI

/// A preset's page: what the camera does, an example and the cost.
struct PresetDetailView: View {
    let preset: Preset
    let onUse: @MainActor () -> Void

    @State private var player: AVPlayer?
    @Environment(\.isWideLayout) private var isWide

    var body: some View {
        ScrollView {
            Group {
                if isWide {
                    HStack(alignment: .top, spacing: Theme.Space.xxl) {
                        media.frame(maxWidth: .infinity)
                        info.frame(width: 320)
                    }
                } else {
                    VStack(alignment: .leading, spacing: Theme.Space.xl) {
                        media
                        info
                    }
                }
            }
            .padding(Theme.Space.l)
        }
        .screenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard player == nil, let url = preset.exampleVideoURL else { return }
            let newPlayer = AVPlayer(url: url)
            newPlayer.isMuted = true
            newPlayer.play()
            player = newPlayer
        }
        .onDisappear { player?.pause() }
    }

    @ViewBuilder
    private var media: some View {
        if let player {
            VideoPlayer(player: player)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
        } else {
            RemoteImage(url: preset.thumbnailURL)
                .aspectRatio(isWide ? 4 / 3 : 4 / 5, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                if preset.tag != nil {
                    Text("New preset").font(.footnote).foregroundStyle(Theme.textSecondary)
                }
                Text(preset.title)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                if let summary = preset.summary {
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GroupedSection {
                ValueRow(title: "Cost", value: "\(preset.cost) credits", mono: true)
                RowDivider()
                ValueRow(title: "Works best with", value: "Portraits, landscapes")
            }

            Button("Use this preset", action: onUse)
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}
