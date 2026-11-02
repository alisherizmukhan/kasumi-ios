import Foundation
import OSLog

enum AnalyticsEvent: Sendable {
    case signedIn(method: String)
    case signedOut
    case presetOpened(id: String)
    case generationStarted(presetID: String?)
    case generationFinished(status: String, seconds: Int)
    case purchaseCompleted(productID: String)
    case savedToPhotos
    case accountDeleted

    var name: String {
        switch self {
        case .signedIn: "signed_in"
        case .signedOut: "signed_out"
        case .presetOpened: "preset_opened"
        case .generationStarted: "generation_started"
        case .generationFinished: "generation_finished"
        case .purchaseCompleted: "purchase_completed"
        case .savedToPhotos: "saved_to_photos"
        case .accountDeleted: "account_deleted"
        }
    }

    var parameters: [String: String] {
        switch self {
        case .signedIn(let method): ["method": method]
        case .presetOpened(let id): ["preset_id": id]
        case .generationStarted(let presetID): ["preset_id": presetID ?? "none"]
        case .generationFinished(let status, let seconds): ["status": status, "seconds": String(seconds)]
        case .purchaseCompleted(let productID): ["product_id": productID]
        case .signedOut, .savedToPhotos, .accountDeleted: [:]
        }
    }
}

/// Vendor-neutral analytics. Swap `LogAnalytics` for Amplitude / Firebase without touching features.
protocol Analytics: Sendable {
    func track(_ event: AnalyticsEvent)
}

/// Vendor-neutral crash and error reporting (Crashlytics / Sentry in production).
protocol CrashReporter: Sendable {
    func record(_ error: any Error, context: String)
    func setUser(id: String?)
}

struct LogAnalytics: Analytics {
    private let logger = Logger(subsystem: "com.alisherizmukhan.Kasumi", category: "analytics")

    func track(_ event: AnalyticsEvent) {
        logger.info("\(event.name, privacy: .public) \(event.parameters.description, privacy: .public)")
    }
}

struct LogCrashReporter: CrashReporter {
    private let logger = Logger(subsystem: "com.alisherizmukhan.Kasumi", category: "errors")

    func record(_ error: any Error, context: String) {
        logger.error("[\(context, privacy: .public)] \(error.localizedDescription, privacy: .public)")
    }

    func setUser(id: String?) {
        logger.info("crash reporter user: \(id ?? "none", privacy: .private)")
    }
}
