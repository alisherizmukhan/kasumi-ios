import Foundation

struct Generation: Codable, Identifiable, Hashable, Sendable {
    enum Status: String, Codable, Sendable {
        case queued, processing, completed, failed

        var label: String {
            switch self {
            case .queued: "In queue"
            case .processing: "Generating"
            case .completed: "Ready"
            case .failed: "Failed"
            }
        }
    }

    let id: String
    let prompt: String
    let presetTitle: String?
    var status: Status
    var progress: Double
    var thumbnailURL: URL?
    var videoURL: URL?
    let createdAt: Date

    var isFinished: Bool { status == .completed || status == .failed }

    /// What the renderer is doing right now, in plain words.
    var stage: String {
        switch status {
        case .queued: return "In queue"
        case .completed: return "Ready"
        case .failed: return "Failed"
        case .processing:
            if progress < 0.35 { return "Reading the scene" }
            if progress < 0.75 { return "Moving the camera" }
            return "Rendering frames"
        }
    }

    var title: String {
        if let presetTitle { return presetTitle }
        return prompt.isEmpty ? "Untitled" : String(prompt.prefix(40))
    }
}

struct GenerationRequest: Codable, Sendable {
    let prompt: String
    let presetID: String?
    /// In production the photo is uploaded to a presigned URL first and only its key is sent here.
    let imageData: Data?
}
