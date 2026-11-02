import SwiftUI

/// Design tokens. Colors come from `Brand`; everything else is spacing, radius and motion.
enum Theme {
    static let accent = Brand.accent
    static let background = Brand.background
    static let card = Brand.card
    static let raised = Brand.raised
    static let hairline = Brand.hairline
    static let textPrimary = Brand.textPrimary
    static let textSecondary = Brand.textSecondary
    static let textMuted = Brand.textMuted
    static let negative = Brand.negative

    /// Spacing on a 4pt grid.
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let tag: CGFloat = 6
        static let control: CGFloat = 10
        static let card: CGFloat = 14
        static let panel: CGFloat = 20
    }

    /// One easing curve for the whole app.
    static func ease(_ duration: Double = 0.16) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }
}
