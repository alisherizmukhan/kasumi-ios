import ActivityKit
import SwiftUI
import WidgetKit

/// Lock Screen and Dynamic Island UI for a generation that is still rendering.
struct GenerationLiveActivity: Widget {
    private static let accent = Color(red: 0.66, green: 0.45, blue: 1.0)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GenerationActivityAttributes.self) { context in
            LockScreenView(context: context, accent: Self.accent)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isFinished ? "checkmark.circle.fill" : "sparkles")
                        .font(.title2)
                        .foregroundStyle(Self.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(percentText(context.state))
                        .font(.headline.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: context.state.progress).tint(Self.accent)
                        Text(context.state.stage).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "sparkles").foregroundStyle(Self.accent)
            } compactTrailing: {
                Text(percentText(context.state)).monospacedDigit()
            } minimal: {
                Image(systemName: context.state.isFinished ? "checkmark" : "sparkles")
                    .foregroundStyle(Self.accent)
            }
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<GenerationActivityAttributes>
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: context.state.isFinished ? "checkmark.circle.fill" : "sparkles")
                .font(.title)
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(context.attributes.title).font(.headline).lineLimit(1)
                    Spacer()
                    Text(percentText(context.state)).font(.subheadline.monospacedDigit())
                }
                ProgressView(value: context.state.progress).tint(accent)
                Text(context.state.isFinished ? "Your video is ready. Tap to watch." : context.state.stage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

private func percentText(_ state: GenerationActivityAttributes.ContentState) -> String {
    state.isFinished ? "Done" : "\(Int(state.progress * 100))%"
}
