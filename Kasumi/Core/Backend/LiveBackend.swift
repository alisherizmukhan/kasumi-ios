import Foundation

/// Real API implementation. Not wired by default: the demo build uses `MockBackend`.
struct LiveBackend: Backend {
    let client: APIClient

    func signIn(with provider: AuthProvider) async throws -> AuthSession {
        let path: String
        let body: [String: String]
        switch provider {
        case .apple(let token):
            path = "auth/apple"
            body = ["identityToken": token]
        case .google(let token):
            path = "auth/google"
            body = ["idToken": token]
        case .email(let email, let password):
            path = "auth/email"
            body = ["email": email, "password": password]
        case .demo:
            path = "auth/demo"
            body = [:]
        }
        return try await client.send(.post(path, body: body, requiresAuth: false))
    }

    func currentUser() async throws -> User {
        try await client.send(.get("me"))
    }

    func homeScreen() async throws -> HomeScreen {
        try await client.send(.get("home"))
    }

    func remoteConfig() async throws -> RemoteConfig {
        try await client.send(.get("config"))
    }

    func startGeneration(_ request: GenerationRequest) async throws -> Generation {
        try await client.send(.post("generations", body: request))
    }

    func generation(id: String) async throws -> Generation {
        try await client.send(.get("generations/\(id)"))
    }

    func library() async throws -> [Generation] {
        try await client.send(.get("generations"))
    }

    func redeemPurchase(productID: String, transactionID: UInt64) async throws -> User {
        try await client.send(.post("purchases/apple", body: PurchaseBody(productID: productID, transactionID: transactionID)))
    }

    func billingHistory() async throws -> [BillingEntry] {
        try await client.send(.get("billing"))
    }

    func deleteAccount() async throws {
        let _: EmptyResponse = try await client.send(.post("account/delete", body: [String: String]()))
    }

    private struct PurchaseBody: Encodable {
        let productID: String
        let transactionID: UInt64
    }
}
