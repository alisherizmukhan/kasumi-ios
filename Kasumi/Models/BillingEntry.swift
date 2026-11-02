import Foundation

/// One line in the account's billing history: credits added or spent.
struct BillingEntry: Codable, Identifiable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case purchase, subscription, generation, bonus, refund
    }

    let id: String
    let date: Date
    let kind: Kind
    let title: String
    /// Positive when credits were added, negative when spent.
    let credits: Int
    /// What the user paid, for purchases and subscriptions.
    let price: String?
}
