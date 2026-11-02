import XCTest
@testable import Kasumi

final class HomeScreenTests: XCTestCase {
    func testSkipsUnknownAndMalformedSections() throws {
        let json = """
        {
          "sections": [
            { "type": "hero", "id": "hero", "title": "T", "subtitle": "S", "imageURL": "https://example.com/a.jpg" },
            { "type": "countdown", "id": "future", "endsAt": "2026-12-31T00:00:00Z" },
            { "type": "grid", "id": "broken" },
            { "type": "carousel", "id": "row", "title": "Trending", "items": [
              { "id": "p1", "title": "Preset", "thumbnailURL": "https://example.com/p.jpg", "cost": 10 }
            ] }
          ]
        }
        """

        let screen = try JSONDecoder().decode(HomeScreen.self, from: Data(json.utf8))

        XCTAssertEqual(screen.sections.map(\.id), ["hero", "row"])
        XCTAssertEqual(screen.allPresets.map(\.id), ["p1"])
    }

    func testBundledHomeScreenDecodes() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "home", withExtension: "json"))
        let screen = try JSONDecoder().decode(HomeScreen.self, from: Data(contentsOf: url))

        // The bundled file contains one section type the app doesn't know yet ("countdown").
        XCTAssertEqual(screen.sections.count, 3)
        XCTAssertFalse(screen.allPresets.isEmpty)
    }

    func testRemoteConfigFallsBackToDefaults() throws {
        let config = try JSONDecoder().decode(RemoteConfig.self, from: Data(#"{"storeEnabled": false}"#.utf8))

        XCTAssertFalse(config.storeEnabled)
        XCTAssertTrue(config.liveActivitiesEnabled)
        XCTAssertEqual(config.maxPromptLength, RemoteConfig().maxPromptLength)
    }
}
