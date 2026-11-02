import SwiftUI

enum LayoutMetrics {
    /// Narrowest width that gets the two-column layout.
    static let wideThreshold: CGFloat = 700
}

private struct WideLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True when the window has room for two columns: the iPhone Duo inner display
    /// (about 890 × 626 pt, landscape) or a large iPhone in landscape.
    /// It follows the window width, so Split View on iPhone Duo falls back to the phone layout.
    var isWideLayout: Bool {
        get { self[WideLayoutKey.self] }
        set { self[WideLayoutKey.self] = newValue }
    }
}

/// Measures the window and publishes `isWideLayout` to everything inside it.
struct WidthClassReader<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { proxy in
            content
                .environment(\.isWideLayout, proxy.size.width >= LayoutMetrics.wideThreshold)
        }
    }
}

extension View {
    /// Keeps forms and lists at a comfortable reading width on wide screens.
    func readableWidth(_ maxWidth: CGFloat = 600) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

/// A tappable row with a chevron, for grouped sections.
struct NavigationRow: View {
    let title: String
    var value: String?
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.s) {
                Text(title).foregroundStyle(Theme.textPrimary)
                Spacer()
                if let value {
                    Text(value).foregroundStyle(Theme.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, Theme.Space.l)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A labelled switch for grouped sections.
struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).foregroundStyle(Theme.textPrimary)
        }
        .tint(Theme.accent)
        .padding(.horizontal, Theme.Space.l)
        .frame(minHeight: 48)
    }
}
