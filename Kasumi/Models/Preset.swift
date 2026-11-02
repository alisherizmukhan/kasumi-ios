import Foundation

struct Preset: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let thumbnailURL: URL
    let cost: Int
    let tag: String?
    /// What the camera does, shown on the preset page.
    let summary: String?
    /// A short example clip rendered with this preset.
    let exampleVideoURL: URL?
}

enum Pricing {
    /// Cost of a generation that uses only a text prompt, without a preset.
    static let promptOnlyCost = 10
}
