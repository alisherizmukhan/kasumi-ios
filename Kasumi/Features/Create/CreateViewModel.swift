import Observation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
@Observable
final class CreateViewModel {
    var pickerItem: PhotosPickerItem?
    var image: UIImage?
    var prompt = ""
    var selectedPreset: Preset?
    private(set) var presets: [Preset] = []
    private(set) var isSubmitting = false
    private(set) var isLoadingImage = false
    var errorMessage: String?

    @ObservationIgnored private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    // MARK: - Derived state

    var maxPromptLength: Int { app.config.maxPromptLength }
    var promptSuggestions: [String] { app.config.promptSuggestions }
    var trimmedPrompt: String { prompt.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isPromptTooLong: Bool { prompt.count > maxPromptLength }
    var cost: Int { selectedPreset?.cost ?? Pricing.promptOnlyCost }

    var canGenerate: Bool {
        image != nil
            && (selectedPreset != nil || !trimmedPrompt.isEmpty)
            && !isPromptTooLong
            && !isSubmitting
    }

    /// Tells the user what is missing instead of silently disabling the button.
    var hint: String? {
        if image == nil { return "Add a photo to start" }
        if selectedPreset == nil && trimmedPrompt.isEmpty { return "Pick a preset or describe the motion" }
        if isPromptTooLong { return "Prompt is too long" }
        return nil
    }

    // MARK: - Actions

    func loadPresets() async {
        guard presets.isEmpty, let screen = try? await app.backend.homeScreen() else { return }
        presets = screen.allPresets
    }

    func loadPickedImage() async {
        guard let pickerItem else { return }
        isLoadingImage = true
        defer { isLoadingImage = false }
        do {
            guard let data = try await pickerItem.loadTransferable(type: Data.self), let picked = UIImage(data: data) else {
                errorMessage = "This photo format isn't supported."
                return
            }
            image = picked
        } catch {
            errorMessage = "Couldn't load this photo."
        }
    }

    func removeImage() {
        image = nil
        pickerItem = nil
    }

    func toggle(_ preset: Preset) {
        selectedPreset = selectedPreset == preset ? nil : preset
    }

    func generate() async {
        guard canGenerate, let image else { return }
        guard (app.user?.credits ?? 0) >= cost else {
            errorMessage = BackendError.insufficientCredits.localizedDescription
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let request = GenerationRequest(
            prompt: trimmedPrompt,
            presetID: selectedPreset?.id,
            imageData: image.jpegData(compressionQuality: 0.8)
        )
        do {
            let generation = try await app.backend.startGeneration(request)
            app.generations.track(generation, sourceImage: image, liveActivity: app.liveActivitiesAllowed)
            app.analytics.track(.generationStarted(presetID: request.presetID))
            prompt = ""
            await app.refreshUser()
            await app.requestNotificationPermissionIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
            app.crashReporter.record(error, context: "generate")
        }
    }

    // MARK: - Demo

    /// Fills the form and starts a generation so the screenshot shows a realistic state.
    func prepareDemo() async {
        await loadPresets()
        if let url = URL(string: "https://picsum.photos/seed/portrait/800/1000"),
           let response = try? await URLSession.shared.data(from: url) {
            image = UIImage(data: response.0)
        }
        selectedPreset = presets.dropFirst().first
        prompt = "Slow cinematic push-in"
        await generate()
        prompt = "Golden hour, soft wind"
    }
}
