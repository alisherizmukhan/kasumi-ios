import Foundation
import Observation
import Photos

@MainActor
@Observable
final class GenerationDetailViewModel {
    enum SaveState: Equatable {
        case idle, saving, saved
        case failed(String)
    }

    let generation: Generation
    private(set) var saveState: SaveState = .idle

    @ObservationIgnored private let analytics: any Analytics

    init(generation: Generation, analytics: any Analytics) {
        self.generation = generation
        self.analytics = analytics
    }

    func saveToPhotos() async {
        guard let url = generation.videoURL, saveState != .saving else { return }
        saveState = .saving
        do {
            try await Self.downloadAndSave(url)
            saveState = .saved
            analytics.track(.savedToPhotos)
        } catch {
            saveState = .failed(error.localizedDescription)
        }
    }

    nonisolated private static func downloadAndSave(_ remoteURL: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.permissionDenied }

        let (downloadedURL, _) = try await URLSession.shared.download(from: remoteURL)
        let fileURL = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        try FileManager.default.moveItem(at: downloadedURL, to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        try await PHPhotoLibrary.shared().performChanges {
            _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }

    enum SaveError: LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            "Allow Lumen to add to Photos in Settings to save videos."
        }
    }
}
