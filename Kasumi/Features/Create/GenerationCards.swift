import SwiftUI
import UIKit

/// A generation that is still rendering: the photo it started from, the current stage
/// and an estimate of the time left.
struct RenderingCard: View {
    let generation: Generation
    let sourceImage: UIImage?
    let secondsRemaining: Int?

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Thumbnail(image: sourceImage, url: nil)
                .overlay {
                    ZStack {
                        Theme.background.opacity(0.45)
                        ProgressRing(progress: generation.progress)
                            .frame(width: 24, height: 24)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

            VStack(alignment: .leading, spacing: Theme.Space.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text(generation.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(generation.progress * 100))%")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                        .contentTransition(.numericText(value: generation.progress))
                }

                ProgressView(value: generation.progress)
                    .tint(Theme.accent)

                HStack {
                    Text(generation.stage)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    if let secondsRemaining {
                        Text("About \(secondsRemaining) s left")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
        }
        .padding(Theme.Space.m)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).strokeBorder(Theme.hairline))
        .animation(Theme.ease(0.3), value: generation.progress)
        .accessibilityElement(children: .combine)
    }
}

/// A generation that finished in this session, with a shortcut to watch it.
struct ReadyCard: View {
    let generation: Generation
    let onWatch: @MainActor () -> Void
    let onDismiss: @MainActor () -> Void

    private var isReady: Bool { generation.status == .completed }

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Thumbnail(image: nil, url: generation.thumbnailURL)
                .overlay {
                    if isReady {
                        Image(systemName: "play.fill")
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.black.opacity(0.5), in: Circle())
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(generation.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(isReady ? "Ready to watch" : "Couldn't render. Credits were refunded")
                    .font(.footnote)
                    .foregroundStyle(isReady ? Theme.textSecondary : Theme.negative)
            }

            Spacer(minLength: Theme.Space.s)

            if isReady {
                Button("Watch", action: onWatch)
                    .buttonStyle(SecondaryButtonStyle(height: 36))
                    .frame(width: 88)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(.leading, Theme.Space.m)
        .padding(.vertical, Theme.Space.m)
        .padding(.trailing, Theme.Space.xs)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).strokeBorder(Theme.hairline))
    }
}

/// Small 3:4 preview: a local photo, a remote thumbnail or a quiet placeholder.
private struct Thumbnail: View {
    let image: UIImage?
    let url: URL?

    var body: some View {
        Group {
            if let image {
                Color.clear.overlay {
                    Image(uiImage: image).resizable().scaledToFill()
                }
                .clipped()
            } else {
                RemoteImage(url: url)
            }
        }
        .frame(width: 54, height: 72)
    }
}
