import SwiftUI

/// A grey block in the shape of content that is still loading. It breathes slowly
/// to show that something is happening, and stays still with Reduce Motion on.
struct SkeletonBlock: View {
    var cornerRadius: CGFloat = Theme.Radius.card
    @State private var isDimmed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Theme.raised)
            .opacity(isDimmed ? 0.55 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isDimmed = true
                }
            }
            .accessibilityHidden(true)
    }
}

/// Placeholder for the server-driven home screen: a hero, a row of presets and a grid.
struct HomeSkeleton: View {
    @Environment(\.isWideLayout) private var isWide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xxl) {
                SkeletonBlock(cornerRadius: Theme.Radius.panel)
                    .frame(height: isWide ? 320 : 280)

                VStack(alignment: .leading, spacing: Theme.Space.m) {
                    SkeletonBlock(cornerRadius: 6).frame(width: 140, height: 20)
                    HStack(spacing: Theme.Space.m) {
                        ForEach(0..<(isWide ? 5 : 3), id: \.self) { _ in
                            SkeletonBlock().frame(width: 152, height: 216)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.top, Theme.Space.s)
        }
        .scrollDisabled(true)
        .accessibilityElement()
        .accessibilityLabel("Loading presets")
    }
}

/// Placeholder grid for the library.
struct LibrarySkeleton: View {
    let columns: [GridItem]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Theme.Space.m) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: Theme.Space.s) {
                        SkeletonBlock().aspectRatio(3 / 4, contentMode: .fit)
                        SkeletonBlock(cornerRadius: 4).frame(width: 100, height: 14)
                        SkeletonBlock(cornerRadius: 4).frame(width: 64, height: 12)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.vertical, Theme.Space.s)
        }
        .scrollDisabled(true)
        .accessibilityElement()
        .accessibilityLabel("Loading your videos")
    }
}
