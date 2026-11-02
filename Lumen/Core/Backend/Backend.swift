import Foundation

/// Everything the app needs from the server. The UI only talks to this protocol,
/// so `MockBackend` (demo) and `LiveBackend` (real API) are interchangeable.
protocol Backend: Sendable {
    func signIn(with provider: AuthProvider) async throws -> AuthSession
    func currentUser() async throws -> User
    func homeScreen() async throws -> HomeScreen
    func remoteConfig() async throws -> RemoteConfig
    func startGeneration(_ request: GenerationRequest) async throws -> Generation
    func generation(id: String) async throws -> Generation
    func library() async throws -> [Generation]
    /// The server verifies the App Store transaction and grants credits.
    func redeemPurchase(productID: String, transactionID: UInt64) async throws -> User
}

enum BackendError: Error, LocalizedError {
    case invalidCredentials
    case insufficientCredits
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: "Wrong email or password."
        case .insufficientCredits: "Not enough credits. Top up in Profile."
        case .notFound: "Not found."
        }
    }
}
