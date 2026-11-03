import XCTest
@testable import Kasumi

final class ProfileTests: XCTestCase {
    func testSummaryCountsFinishedVideosAndThisMonthsSpend() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 15))!
        let lastMonth = calendar.date(from: DateComponents(year: 2026, month: 10, day: 30))!

        func video(_ id: String, _ status: Generation.Status) -> Generation {
            Generation(id: id, prompt: "", presetTitle: "P", status: status, progress: 1, thumbnailURL: nil, videoURL: nil, createdAt: now)
        }
        let videos = [video("1", .completed), video("2", .processing), video("3", .completed)]
        let billing = [
            BillingEntry(id: "a", date: now, kind: .generation, title: "A", credits: -15, price: nil),
            BillingEntry(id: "b", date: now, kind: .purchase, title: "B", credits: 100, price: "$4.99"),
            BillingEntry(id: "c", date: lastMonth, kind: .generation, title: "C", credits: -20, price: nil),
        ]

        let summary = ProfileViewModel.summarize(videos: videos, billing: billing, now: now, calendar: calendar)

        XCTAssertEqual(summary.videoCount, 2)
        XCTAssertEqual(summary.spentThisMonth, 15)
        XCTAssertEqual(summary.recent.map(\.id), ["1", "3"])
    }

    func testStageFollowsProgress() {
        func stage(_ progress: Double) -> String {
            Generation(id: "x", prompt: "", presetTitle: nil, status: .processing, progress: progress, thumbnailURL: nil, videoURL: nil, createdAt: .now).stage
        }
        XCTAssertEqual(stage(0.2), "Reading the scene")
        XCTAssertEqual(stage(0.5), "Moving the camera")
        XCTAssertEqual(stage(0.9), "Rendering frames")
    }
}
