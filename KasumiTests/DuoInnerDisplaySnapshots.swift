import SwiftUI
import UIKit
import XCTest
@testable import Kasumi

/// Renders every demo screen at the size of iPhone Duo's inner display (about 890 × 626 pt,
/// landscape, regular size classes).
///
/// The iPhone Duo simulator boots folded and Xcode 27 has no scriptable way to unfold it,
/// so CI checks the inner-display layout this way and photographs the cover display on the
/// real Duo simulator. Runs only when `SNAPSHOT_DIR` is set (CI passes TEST_RUNNER_SNAPSHOT_DIR).
final class DuoInnerDisplaySnapshots: XCTestCase {
    private static let innerDisplaySize = CGSize(width: 890, height: 626)

    @MainActor
    func testRenderInnerDisplayScreens() async throws {
        guard let directory = ProcessInfo.processInfo.environment["SNAPSHOT_DIR"], !directory.isEmpty else {
            throw XCTSkip("Set SNAPSHOT_DIR to render iPhone Duo inner-display snapshots")
        }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            throw XCTSkip("No window scene")
        }
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        defer { UserDefaults.standard.removeObject(forKey: "demoScreen") }

        for screen in DemoScreen.allCases {
            UserDefaults.standard.set(screen.rawValue, forKey: "demoScreen")
            let app = AppModel.live()
            await app.bootstrap()

            let host = UIHostingController(rootView: Self.root(app: app))
            host.traitOverrides.horizontalSizeClass = .regular
            host.traitOverrides.verticalSizeClass = .regular
            host.traitOverrides.userInterfaceStyle = .dark

            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(origin: .zero, size: Self.innerDisplaySize)
            window.rootViewController = host
            window.isHidden = false

            // Let navigation, remote images and the demo flows settle.
            try await Task.sleep(for: .seconds(8))

            let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let url = URL(fileURLWithPath: directory).appending(path: "\(screen.rawValue).png")
            try XCTUnwrap(image.pngData()).write(to: url)

            window.isHidden = true
            window.rootViewController = nil
        }
    }

    @MainActor
    private static func root(app: AppModel) -> some View {
        WidthClassReader {
            RootView()
        }
        .environment(app)
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .screenBackground()
    }
}
