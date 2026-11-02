import Foundation
import UserNotifications

/// Local notification when a generation is ready. In production the backend sends an APNs push
/// (and updates the Live Activity via push) so the user is notified even if the app was killed.
struct NotificationService: Sendable {
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func notifyFinished(_ generation: Generation) async {
        let content = UNMutableNotificationContent()
        if generation.status == .completed {
            content.title = "Your video is ready ✨"
            content.body = "\(generation.title) finished rendering. Tap to watch."
        } else {
            content.title = "Generation failed"
            content.body = "\(generation.title) couldn't be generated. Your credits were refunded."
        }
        content.sound = .default
        content.userInfo = ["generationID": generation.id]

        let request = UNNotificationRequest(identifier: generation.id, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
