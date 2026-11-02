import SwiftUI

/// Remote image that always fills its frame and shows a placeholder while loading.
struct RemoteImage: View {
    let url: URL?

    var body: some View {
        Rectangle()
            .fill(Theme.card)
            .overlay {
                if let url {
                    AsyncImage(url: url, transaction: SwiftUI.Transaction(animation: .easeOut(duration: 0.25))) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else if phase.error != nil {
                            Image(systemName: "photo").foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "sparkles").font(.title2).foregroundStyle(.secondary)
                }
            }
            .clipped()
    }
}

struct CreditsBadge: View {
    let credits: Int

    var body: some View {
        // HStack instead of Label: toolbars render a Label as icon-only.
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(Theme.gradient)
            Text("\(credits)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(credits)))
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.card, in: Capsule())
        .animation(.snappy, value: credits)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(credits) credits")
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.gradient)
                    .opacity(isEnabled ? 1 : 0.35)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    func inputFieldStyle() -> some View {
        padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.cardBorder))
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
