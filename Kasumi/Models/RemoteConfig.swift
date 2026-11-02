import Foundation

/// Feature flags and tunables fetched at launch. Every field has a safe default,
/// so a missing or old config never breaks the app.
struct RemoteConfig: Decodable, Sendable {
    var liveActivitiesEnabled = true
    var storeEnabled = true
    var maxPromptLength = 300
    var promptSuggestions = [
        "Slow cinematic push-in",
        "Golden hour, soft wind",
        "Handheld, film grain",
        "Orbit around the subject",
    ]

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = RemoteConfig()
        liveActivitiesEnabled = try container.decodeIfPresent(Bool.self, forKey: .liveActivitiesEnabled) ?? defaults.liveActivitiesEnabled
        storeEnabled = try container.decodeIfPresent(Bool.self, forKey: .storeEnabled) ?? defaults.storeEnabled
        maxPromptLength = try container.decodeIfPresent(Int.self, forKey: .maxPromptLength) ?? defaults.maxPromptLength
        promptSuggestions = try container.decodeIfPresent([String].self, forKey: .promptSuggestions) ?? defaults.promptSuggestions
    }

    private enum CodingKeys: String, CodingKey {
        case liveActivitiesEnabled, storeEnabled, maxPromptLength, promptSuggestions
    }
}
