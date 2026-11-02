import Foundation

struct User: Codable, Equatable, Sendable {
    enum Plan: String, Codable, Sendable {
        case free, pro

        var title: String { self == .pro ? "Pro" : "Free" }
    }

    let id: String
    var name: String
    var email: String?
    var credits: Int
    var plan: Plan

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}

struct AuthSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

/// One account for web and mobile: every provider resolves to the same backend user.
enum AuthProvider: Sendable {
    case apple(identityToken: String)
    case google(idToken: String)
    case email(String, password: String)
    case demo

    var analyticsName: String {
        switch self {
        case .apple: "apple"
        case .google: "google"
        case .email: "email"
        case .demo: "demo"
        }
    }
}
