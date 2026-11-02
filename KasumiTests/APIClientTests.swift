import XCTest
@testable import Kasumi

final class APIClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
    }

    func testRetriesServerErrorThenSucceeds() async throws {
        StubURLProtocol.responses = [(503, Data()), (200, Data(#"{"value":"ok"}"#.utf8))]

        let result: Echo = try await makeClient().send(Endpoint(path: "echo", requiresAuth: false))

        XCTAssertEqual(result.value, "ok")
        XCTAssertEqual(StubURLProtocol.requests.count, 2)
    }

    func testDoesNotRetryClientErrors() async {
        StubURLProtocol.responses = [(404, Data())]

        do {
            let _: Echo = try await makeClient().send(Endpoint(path: "echo", requiresAuth: false))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .server(status: 404))
        }
        XCTAssertEqual(StubURLProtocol.requests.count, 1)
    }

    func testGivesUpAfterMaxRetries() async {
        StubURLProtocol.responses = Array(repeating: (500, Data()), count: 5)

        do {
            let _: Echo = try await makeClient().send(Endpoint(path: "echo", requiresAuth: false))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .server(status: 500))
        }
        XCTAssertEqual(StubURLProtocol.requests.count, 3) // 1 attempt + 2 retries
    }

    func testRefreshesTokenOnceOnUnauthorized() async throws {
        let tokens = StubTokens()
        StubURLProtocol.responses = [(401, Data()), (200, Data(#"{"value":"ok"}"#.utf8))]

        let _: Echo = try await makeClient(tokens: tokens).send(Endpoint(path: "me"))

        XCTAssertEqual(StubURLProtocol.requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer old-token")
        XCTAssertEqual(StubURLProtocol.requests.last?.value(forHTTPHeaderField: "Authorization"), "Bearer new-token")
        let refreshCount = await tokens.refreshCount
        XCTAssertEqual(refreshCount, 1)
    }

    func testMapsInvalidJSONToDecodingError() async {
        StubURLProtocol.responses = [(200, Data("not json".utf8))]

        do {
            let _: Echo = try await makeClient().send(Endpoint(path: "echo", requiresAuth: false))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .decoding)
        }
    }

    // MARK: - Helpers

    private func makeClient(tokens: (any TokenProvider)? = nil) -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return APIClient(
            baseURL: URL(string: "https://api.example.com")!,
            session: URLSession(configuration: configuration),
            tokens: tokens,
            retryBaseDelay: .milliseconds(1)
        )
    }
}

private struct Echo: Decodable, Sendable {
    let value: String
}

private actor StubTokens: TokenProvider {
    private var token = "old-token"
    private(set) var refreshCount = 0

    func accessToken() -> String? { token }

    func refreshAccessToken() throws -> String {
        refreshCount += 1
        token = "new-token"
        return token
    }
}

/// Serves canned responses in order and records every request.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responses: [(Int, Data)] = []
    nonisolated(unsafe) static var requests: [URLRequest] = []

    static func reset() {
        responses = []
        requests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        let (status, data) = Self.responses.isEmpty ? (200, Data("{}".utf8)) : Self.responses.removeFirst()
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
