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

/// Balance in the toolbar: a figure and its unit, no icon.
struct CreditsBadge: View {
    let credits: Int

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            Text("\(credits)")
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText(value: Double(credits)))
            Text("credits")
                .foregroundStyle(Theme.textMuted)
        }
        .font(.footnote.monospacedDigit())
        .padding(.horizontal, Theme.Space.s)
        .frame(height: 28)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.tag, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tag, style: .continuous).strokeBorder(Theme.hairline))
        .animation(Theme.ease(0.3), value: credits)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(credits) credits")
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

    func creditsToolbar(_ credits: Int?) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CreditsBadge(credits: credits ?? 0)
            }
        }
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
