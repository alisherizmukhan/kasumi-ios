import Foundation

/// Server-driven home screen. Marketing changes the layout on the backend, no app release needed.
///
/// Compatibility rules:
/// - Unknown section types (added for newer app versions) are skipped.
/// - A malformed section is skipped instead of failing the whole screen.
struct HomeScreen: Decodable, Sendable {
    let sections: [HomeSection]

    init(sections: [HomeSection]) {
        self.sections = sections
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sections = try container.decode([LossySection].self, forKey: .sections).compactMap(\.section)
    }

    var allPresets: [Preset] {
        var seen = Set<String>()
        return sections.flatMap(\.presets).filter { seen.insert($0.id).inserted }
    }

    private enum CodingKeys: String, CodingKey {
        case sections
    }

    /// Never throws, so one bad element can't break decoding of the array.
    private struct LossySection: Decodable {
        let section: HomeSection?

        init(from decoder: Decoder) {
            section = try? HomeSection(from: decoder)
        }
    }
}

enum HomeSection: Decodable, Identifiable, Sendable {
    case hero(Hero)
    case carousel(PresetRow)
    case grid(PresetRow)

    struct Hero: Decodable, Sendable {
        let id: String
        let title: String
        let subtitle: String
        let imageURL: URL
        let preset: Preset?
    }

    struct PresetRow: Decodable, Sendable {
        let id: String
        let title: String
        let items: [Preset]
    }

    struct UnsupportedSectionError: Error {
        let type: String
    }

    var id: String {
        switch self {
        case .hero(let hero): hero.id
        case .carousel(let row), .grid(let row): row.id
        }
    }

    var presets: [Preset] {
        switch self {
        case .hero(let hero): [hero.preset].compactMap { $0 }
        case .carousel(let row), .grid(let row): row.items
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "hero": self = .hero(try Hero(from: decoder))
        case "carousel": self = .carousel(try PresetRow(from: decoder))
        case "grid": self = .grid(try PresetRow(from: decoder))
        default: throw UnsupportedSectionError(type: type)
        }
    }
}
