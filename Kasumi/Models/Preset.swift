import Foundation

struct Preset: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let thumbnailURL: URL
    let cost: Int
    let tag: String?
}

enum Pricing {
    /// Cost of a generation that uses only a text prompt, without a preset.
    static let promptOnlyCost = 10
}
