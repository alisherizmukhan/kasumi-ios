import Foundation

/// User preferences stored on the device. Views bind to the same keys with `@AppStorage`.
enum AppSettings {
    static let notifyWhenReadyKey = "settings.notifyWhenReady"
    static let liveActivitiesKey = "settings.liveActivities"
    static let autoSaveKey = "settings.autoSave"
    static let exportQualityKey = "settings.exportQuality"
    static let onboardingDoneKey = "onboarding.done"

    static var notifyWhenReady: Bool { bool(notifyWhenReadyKey, default: true) }
    static var liveActivities: Bool { bool(liveActivitiesKey, default: true) }

    private static func bool(_ key: String, default value: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? value
    }
}
