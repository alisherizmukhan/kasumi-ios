import UIKit
import XCTest
@testable import Lumen

final class GenerationFlowTests: XCTestCase {
    func testGenerationChargesCreditsAndCompletes() async throws {
        let backend = MockBackend(latency: .zero, generationDuration: 0.05)
        let before = try await backend.currentUser().credits

        let started = try await backend.startGeneration(GenerationRequest(prompt: "test", presetID: nil, imageData: nil))
        let after = try await backend.currentUser().credits
        XCTAssertEqual(before - after, Pricing.promptOnlyCost)
        XCTAssertEqual(started.status, .queued)

        try await Task.sleep(for: .milliseconds(100))
        let finished = try await backend.generation(id: started.id)
        XCTAssertEqual(finished.status, .completed)
        XCTAssertNotNil(finished.videoURL)
    }

    func testRejectsGenerationWithoutEnoughCredits() async throws {
        let backend = MockBackend(latency: .zero)
        let credits = try await backend.currentUser().credits
        for _ in 0..<(credits / Pricing.promptOnlyCost) {
            _ = try await backend.startGeneration(GenerationRequest(prompt: "test", presetID: nil, imageData: nil))
        }

        do {
            _ = try await backend.startGeneration(GenerationRequest(prompt: "test", presetID: nil, imageData: nil))
            XCTFail("Expected insufficient credits")
        } catch BackendError.insufficientCredits {
            // expected
        }
    }

    @MainActor
    func testCreateFormValidation() {
        let viewModel = CreateViewModel(app: AppModel(backend: MockBackend(latency: .zero)))
        XCTAssertFalse(viewModel.canGenerate)
        XCTAssertEqual(viewModel.hint, "Add a photo to start")

        viewModel.image = UIImage(systemName: "photo")
        viewModel.prompt = "   "
        XCTAssertFalse(viewModel.canGenerate)

        viewModel.prompt = "slow push-in"
        XCTAssertTrue(viewModel.canGenerate)
        XCTAssertEqual(viewModel.cost, Pricing.promptOnlyCost)

        viewModel.prompt = String(repeating: "a", count: viewModel.maxPromptLength + 1)
        XCTAssertFalse(viewModel.canGenerate)
    }
}
