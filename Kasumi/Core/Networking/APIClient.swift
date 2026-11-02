import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

/// A typed description of one API call. `Response` is the type the body decodes into.
struct Endpoint<Response: Decodable & Sendable>: Sendable {
    var method: HTTPMethod = .get
    var path: String
    var body: Data?
    var requiresAuth = true

    static func get(_ path: String) -> Endpoint {
        Endpoint(path: path)
    }

    static func post(_ path: String, body: some Encodable, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(method: .post, path: path, body: try? JSONEncoder().encode(body), requiresAuth: requiresAuth)
    }
}

enum APIError: Error, Equatable, LocalizedError {
    case unauthorized
    case server(status: Int)
    case transport(URLError.Code)
    case decoding
    case invalidResponse

    /// Only transient failures are retried. 4xx errors will fail the same way again.
    var isRetryable: Bool {
        switch self {
        case .server(let status):
            status >= 500 || status == 429
        case .transport(let code):
            [.timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost].contains(code)
        default:
            false
        }
    }

    var errorDescription: String? {
        switch self {
        case .unauthorized: "Your session has expired. Please sign in again."
        case .server(let status) where status >= 500: "Our servers are having trouble. Please try again."
        case .server: "The request couldn't be completed."
        case .transport: "No connection. Check your internet and try again."
        case .decoding, .invalidResponse: "Unexpected response from the server."
        }
    }
}

protocol TokenProvider: Sendable {
    func accessToken() async -> String?
    /// Exchanges the refresh token for a new access token.
    func refreshAccessToken() async throws -> String
}

/// Thin network layer: auth header, one token refresh on 401, retries with exponential backoff
/// for transient errors, typed decoding. HTTP caching (ETag / Cache-Control) is handled by URLCache.
final class APIClient: Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let tokens: (any TokenProvider)?
    private let maxRetries: Int
    private let retryBaseDelay: Duration

    init(
        baseURL: URL,
        session: URLSession = APIClient.makeSession(),
        tokens: (any TokenProvider)? = nil,
        maxRetries: Int = 2,
        retryBaseDelay: Duration = .milliseconds(400)
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokens = tokens
        self.maxRetries = maxRetries
        self.retryBaseDelay = retryBaseDelay
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.timeoutIntervalForRequest = 20
        return URLSession(configuration: configuration)
    }

    func send<T>(_ endpoint: Endpoint<T>) async throws -> T {
        var attempt = 0
        var didRefreshToken = false

        while true {
            do {
                return try await perform(endpoint)
            } catch APIError.unauthorized where endpoint.requiresAuth && !didRefreshToken {
                guard let tokens else { throw APIError.unauthorized }
                _ = try await tokens.refreshAccessToken()
                didRefreshToken = true
            } catch let error as APIError where error.isRetryable && attempt < maxRetries {
                attempt += 1
                try await Task.sleep(for: retryBaseDelay * (1 << (attempt - 1)))
            }
        }
    }

    private func perform<T>(_ endpoint: Endpoint<T>) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: endpoint.path))
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if endpoint.requiresAuth, let token = await tokens?.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.transport(error.code)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch http.statusCode {
        case 200..<300: break
        case 401: throw APIError.unauthorized
        default: throw APIError.server(status: http.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
