import SwiftUI

/// Three short pages before sign-in: what Kasumi does, how you pick a move, and what happens while it renders.
struct OnboardingView: View {
    let onFinish: @MainActor () -> Void

    @State private var page = 0
    @Environment(\.isWideLayout) private var isWide

    private let pages = OnboardingPage.allCases
    private var isLast: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip", action: onFinish)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .opacity(isLast ? 0 : 1)
                    .disabled(isLast)
            }
            .padding(.horizontal, Theme.Space.l)
            .frame(height: 44)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .padding(.horizontal, Theme.Space.xl)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: Theme.Space.xl) {
                HStack(spacing: Theme.Space.s) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Theme.textPrimary : Theme.raised)
                            .frame(width: index == page ? 16 : 6, height: 6)
                    }
                }
                .animation(Theme.ease(0.3), value: page)
                .accessibilityHidden(true)

                Button(isLast ? "Get started" : "Continue") {
                    if isLast {
                        onFinish()
                    } else {
                        withAnimation(Theme.ease(0.3)) { page += 1 }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 400)
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.bottom, Theme.Space.l)
        }
        .screenBackground()
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        if isWide {
            HStack(spacing: 64) {
                page.illustration.frame(maxWidth: .infinity)
                text(for: page).frame(maxWidth: 380, alignment: .leading)
            }
            .readableWidth(880)
        } else {
            VStack(alignment: .leading, spacing: Theme.Space.xxl) {
                Spacer(minLength: 0)
                page.illustration.frame(maxWidth: .infinity)
                text(for: page)
                Spacer(minLength: 0)
            }
        }
    }

    private func text(for page: OnboardingPage) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text(page.title)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(page.message)
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum OnboardingPage: CaseIterable {
    case photo, moves, progress

    var title: String {
        switch self {
        case .photo: "One photo, one camera move"
        case .moves: "Pick a move or describe it"
        case .progress: "Leave the app while it renders"
        }
    }

    var message: String {
        switch self {
        case .photo: "Kasumi turns a still photo into a short clip, as if a camera moved through the scene"
        case .moves: "Start from presets like Dolly Zoom and Earth Zoom Out, or write the motion in your own words"
        case .progress: "A video takes a few minutes. Follow it on the Lock Screen and get a notification when it's ready"
        }
    }

    @MainActor @ViewBuilder
    var illustration: some View {
        switch self {
        case .photo:
            RemoteImage(url: URL(string: "https://picsum.photos/seed/portrait/600/800"))
                .frame(width: 220, height: 288)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
                .overlay { ViewfinderMarks() }

        case .moves:
            HStack(spacing: Theme.Space.s) {
                ForEach(Self.samplePresets) { preset in
                    PresetCard(preset: preset, showsDetails: false)
                        .frame(width: 100, height: 140)
                }
            }

        case .progress:
            VStack(spacing: Theme.Space.m) {
                HStack(spacing: Theme.Space.m) {
                    KasumiMark()
                        .fill(Theme.accent)
                        .frame(width: 28, height: 28)
                        .frame(width: 40, height: 40)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kasumi").font(.footnote).foregroundStyle(Theme.textMuted)
                        Text("Your video is ready").font(.subheadline.weight(.medium)).foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                    Text("now").font(.footnote).foregroundStyle(Theme.textMuted)
                }
                .padding(Theme.Space.m)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).strokeBorder(Theme.hairline))

                ActiveGenerationRow(generation: Self.sampleGeneration)
            }
            .frame(maxWidth: 340)
        }
    }

    private static let samplePresets: [Preset] = [
        samplePreset(id: "dolly_zoom", title: "Dolly Zoom", seed: "dolly"),
        samplePreset(id: "earth_zoom_out", title: "Earth Zoom Out", seed: "earthzoom"),
        samplePreset(id: "fpv_drone", title: "FPV Drone", seed: "drone"),
    ]

    private static func samplePreset(id: String, title: String, seed: String) -> Preset {
        Preset(
            id: id,
            title: title,
            thumbnailURL: URL(string: "https://picsum.photos/seed/\(seed)/400/600")!,
            cost: 15,
            tag: nil,
            summary: nil,
            exampleVideoURL: nil
        )
    }

    private static let sampleGeneration = Generation(
        id: "onboarding",
        prompt: "",
        presetTitle: "Neon Glow",
        status: .processing,
        progress: 0.64,
        thumbnailURL: nil,
        videoURL: nil,
        createdAt: .now
    )
}
