import XCTest
@testable import Kasumi

final class BillingTests: XCTestCase {
    func testPurchaseAndGenerationAreRecorded() async throws {
        let backend = MockBackend(latency: .zero)
        let before = try await backend.billingHistory().count

        _ = try await backend.redeemPurchase(productID: "kasumi.credits.100", transactionID: 1)
        _ = try await backend.startGeneration(GenerationRequest(prompt: "test", presetID: nil, imageData: nil))

        let history = try await backend.billingHistory()
        XCTAssertEqual(history.count, before + 2)
        XCTAssertEqual(history[0].credits, -Pricing.promptOnlyCost)
        XCTAssertEqual(history[1].credits, 100)
        XCTAssertEqual(history[1].price, "$4.99")
    }

    func testSeedHistoryAddsUpToStartingBalance() async throws {
        let backend = MockBackend(latency: .zero)
        let total = try await backend.billingHistory().reduce(0) { $0 + $1.credits }
        let credits = try await backend.currentUser().credits
        XCTAssertEqual(total, credits)
    }

    @MainActor
    func testGroupsEntriesByMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        func date(_ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
        }
        let entries = [
            BillingEntry(id: "3", date: date(11, 2), kind: .generation, title: "C", credits: -15, price: nil),
            BillingEntry(id: "2", date: date(11, 1), kind: .purchase, title: "B", credits: 100, price: "$4.99"),
            BillingEntry(id: "1", date: date(10, 20), kind: .bonus, title: "A", credits: 70, price: nil),
        ]

        let months = BillingHistoryViewModel.groupByMonth(entries, calendar: calendar)

        XCTAssertEqual(months.map(\.entries.count), [2, 1])
        XCTAssertEqual(months.first?.entries.map(\.id), ["3", "2"])
    }

    @MainActor
    func testYearlySavingsUsesDemoCatalog() {
        let monthly = StoreCatalog.demoProducts.first { $0.id == "kasumi.pro.monthly" }
        let yearly = StoreCatalog.demoProducts.first { $0.id == "kasumi.pro.yearly" }
        XCTAssertEqual(monthly?.kind, .subscription(.month))
        XCTAssertEqual(yearly?.credits, StoreCatalog.proMonthlyCredits)
    }
}
