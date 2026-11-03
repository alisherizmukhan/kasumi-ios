import ActivityKit
import Foundation
import Observation
import UIKit

/// Follows generations that are still rendering: polls the backend, keeps the
/// Live Activity in sync and sends a notification when a video is ready.
@MainActor
@Observable
final class GenerationTracker {
    private(set) var active: [Generation] = []
    /// Finished in this session and not dismissed yet, newest first.
    private(set) var recentlyFinished: [Generation] = []
    /// Changes whenever a generation starts or finishes, so lists know to reload.
    private(set) var changeToken = 0
    /// The photo each generation started from, shown while it renders.
    private(set) var sourceImages: [String: UIImage] = [:]
    @ObservationIgnored private var startDates: [String: Date] = [:]

    @ObservationIgnored private let backend: any Backend
    @ObservationIgnored private let analytics: any Analytics
    @ObservationIgnored private let notifications = NotificationService()
    @ObservationIgnored private var pollTasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var activityIDs: [String: String] = [:]
    @ObservationIgnored var pollInterval: Duration = .seconds(1)

    init(backend: any Backend, analytics: any Analytics) {
        self.backend = backend
        self.analytics = analytics
    }

    func track(_ generation: Generation, sourceImage: UIImage? = nil, liveActivity: Bool) {
        upsert(generation)
        sourceImages[generation.id] = sourceImage
        startDates[generation.id] = .now
        changeToken += 1
        if liveActivity { startActivity(for: generation) }
        pollTasks[generation.id] = Task { [weak self] in
            await self?.poll(id: generation.id)
        }
    }

    /// The freshest known state of a generation (live progress if it's still rendering).
    func latest(_ generation: Generation) -> Generation {
        active.first { $0.id == generation.id } ?? generation
    }

    /// Estimated seconds left, from how fast progress has moved so far.
    func secondsRemaining(for generation: Generation) -> Int? {
        guard let start = startDates[generation.id], generation.progress >= 0.1, generation.progress < 1 else { return nil }
        let elapsed = Date().timeIntervalSince(start)
        return max(1, Int((elapsed * (1 - generation.progress) / generation.progress).rounded()))
    }

    func dismissFinished(_ generation: Generation) {
        recentlyFinished.removeAll { $0.id == generation.id }
    }

    private func poll(id: String) async {
        let startedAt = Date()
        while !Task.isCancelled {
            try? await Task.sleep(for: pollInterval)
            guard let generation = try? await backend.generation(id: id) else { continue }
            upsert(generation)
            await syncActivity(with: generation)
            if generation.isFinished {
                finish(generation, seconds: Int(Date().timeIntervalSince(startedAt)))
                return
            }
        }
    }

    private func finish(_ generation: Generation, seconds: Int) {
        active.removeAll { $0.id == generation.id }
        recentlyFinished.insert(generation, at: 0)
        recentlyFinished = Array(recentlyFinished.prefix(3))
        pollTasks[generation.id] = nil
        startDates[generation.id] = nil
        changeToken += 1
        analytics.track(.generationFinished(status: generation.status.rawValue, seconds: seconds))
        if AppSettings.notifyWhenReady {
            Task { await notifications.notifyFinished(generation) }
        }
    }

    private func upsert(_ generation: Generation) {
        if let index = active.firstIndex(where: { $0.id == generation.id }) {
            active[index] = generation
        } else {
            active.insert(generation, at: 0)
        }
    }

    // MARK: - Live Activity

    private func startActivity(for generation: Generation) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = GenerationActivityAttributes(generationID: generation.id, title: generation.title)
        let state = Self.activityState(for: generation)
        let activity = try? Activity<GenerationActivityAttributes>.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil),
            pushType: nil
        )
        if let activity { activityIDs[generation.id] = activity.id }
    }

    private func syncActivity(with generation: Generation) async {
        guard let activityID = activityIDs[generation.id] else { return }
        if generation.isFinished { activityIDs[generation.id] = nil }
        await Self.pushActivityState(Self.activityState(for: generation), activityID: activityID, end: generation.isFinished)
    }

    private static func activityState(for generation: Generation) -> GenerationActivityAttributes.ContentState {
        .init(progress: generation.progress, stage: generation.status.label, isFinished: generation.isFinished)
    }

    nonisolated private static func pushActivityState(
        _ state: GenerationActivityAttributes.ContentState,
        activityID: String,
        end: Bool
    ) async {
        guard let activity = Activity<GenerationActivityAttributes>.activities.first(where: { $0.id == activityID }) else { return }
        let content = ActivityContent(state: state, staleDate: nil)
        if end {
            await activity.end(content, dismissalPolicy: .after(.now.addingTimeInterval(15 * 60)))
        } else {
            await activity.update(content)
        }
    }
}
