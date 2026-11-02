import ActivityKit
import Foundation

/// Shared between the app (starts and updates the activity) and the widget extension (renders it).
struct GenerationActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var progress: Double
        var stage: String
        var isFinished: Bool
    }

    var generationID: String
    var title: String
}
