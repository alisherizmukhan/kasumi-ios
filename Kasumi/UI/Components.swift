import SwiftUI

/// Remote image that always fills its frame and shows a quiet placeholder while loading.
struct RemoteImage: View {
    let url: URL?

    var body: some View {
        Rectangle()
            .fill(Theme.raised)
            .overlay {
                if let url {
                    AsyncImage(url: url, transaction: SwiftUI.Transaction(animation: Theme.ease(0.3))) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else if phase.error != nil {
                            Image(systemName: "photo").foregroundStyle(Theme.textMuted)
                        }
                    }
                } else {
                    Image(systemName: "film").foregroundStyle(Theme.textMuted)
                }
            }
            .clipped()
    }
}

/// Balance in the toolbar. On iOS 26+ the toolbar draws the glass bubble around it,
/// so the badge itself stays flat; older systems get a quiet surface instead.
struct CreditsBadge: View {
    let credits: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 8, height: 8)
            Text("\(credits)")
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText(value: Double(credits)))
            Text("credits")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .modifier(LegacyToolbarSurface())
        .animation(Theme.ease(0.3), value: credits)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(credits) credits")
        .accessibilityHint("Opens the credits store")
    }
}

/// Before iOS 26 toolbar items have no glass, so give the badge its own surface.
private struct LegacyToolbarSurface: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.padding(.horizontal, Theme.Space.xs)
        } else {
            content
                .padding(.horizontal, Theme.Space.m)
                .frame(height: 32)
                .background(Theme.card, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.hairline))
        }
    }
}

/// Primary action: off-white fill with dark text. One per screen.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(isEnabled ? Theme.background : Theme.textMuted)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                isEnabled ? Theme.textPrimary : Theme.raised,
                in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.ease(), value: configuration.isPressed)
    }
}

/// Secondary action: raised surface with a hairline.
struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = 48
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(isEnabled ? Theme.textPrimary : Theme.textMuted)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                configuration.isPressed ? Theme.card : Theme.raised,
                in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(Theme.hairline)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.ease(), value: configuration.isPressed)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.weight(.medium))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Viewfinder corner marks around a frame. Kasumi's signature detail: it appears only
/// around the photo being animated and the finished video.
struct ViewfinderMarks: View {
    var inset: CGFloat = Theme.Space.m
    var length: CGFloat = 20

    var body: some View {
        GeometryReader { proxy in
            let rect = proxy.frame(in: .local).insetBy(dx: inset, dy: inset)
            let corners: [(CGPoint, CGFloat, CGFloat)] = [
                (CGPoint(x: rect.minX, y: rect.minY), 1, 1),
                (CGPoint(x: rect.maxX, y: rect.minY), -1, 1),
                (CGPoint(x: rect.minX, y: rect.maxY), 1, -1),
                (CGPoint(x: rect.maxX, y: rect.maxY), -1, -1),
            ]
            Path { path in
                for (corner, dx, dy) in corners {
                    path.move(to: CGPoint(x: corner.x + dx * length, y: corner.y))
                    path.addLine(to: corner)
                    path.addLine(to: CGPoint(x: corner.x, y: corner.y + dy * length))
                }
            }
            .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Neutral scrim under text that sits on top of an image.
struct ImageScrim: View {
    var body: some View {
        LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
    }
}

extension View {
    func inputFieldStyle() -> some View {
        padding(Theme.Space.m)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous).strokeBorder(Theme.hairline))
    }

    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    /// The balance in the top bar; tapping it opens the credits store.
    func creditsToolbar(_ app: AppModel) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    app.isStorePresented = true
                } label: {
                    CreditsBadge(credits: app.user?.credits ?? 0)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Large titles on a phone; on iPhone Duo's short, wide inner display an inline title
    /// leaves more room for content.
    func adaptiveTitleDisplay(_ isWide: Bool) -> some View {
        navigationBarTitleDisplayMode(isWide ? .inline : .large)
    }

    func errorAlert(_ message: Binding<String?>) -> some View {
        alert(
            "Something went wrong",
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}
