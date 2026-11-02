import SwiftUI

/// Brand colors and the logo mark, shared by the app and the Live Activity extension.
///
/// Kasumi (霞) is the haze that hangs over a landscape at dawn. Surfaces stay a neutral
/// graphite so photos and videos carry the color; the one accent is the warm light
/// coming through the haze.
enum Brand {
    static let accent = Color(hex: 0xF2A65A)
    /// Dark text for use on top of the accent (contrast above 9:1).
    static let onAccent = Color(hex: 0x141415)

    static let background = Color(hex: 0x141415)
    static let deep = Color(hex: 0x0F0F10)
    static let card = Color(hex: 0x19191B)
    static let raised = Color(hex: 0x232325)

    static let textPrimary = Color(hex: 0xEDEDED)
    static let textSecondary = Color(hex: 0xA1A1A6)
    static let textMuted = Color(hex: 0x85858B)
    static let hairline = Color(hex: 0xEDEDED).opacity(0.08)

    static let negative = Color(hex: 0xE5484D)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// The logo mark: a sun with two bands of mist passing in front of it, after the
/// suyari-gasumi bands in Japanese screen painting. One flat colour; the bands are
/// separated from the sun by a thin gap.
/// The same geometry is drawn by `scripts/make_icon.py` for the app icon.
struct KasumiMark: Shape {
    // Geometry in a unit square (0...1).
    private static let sun = (x: 0.48, y: 0.46, radius: 0.24)
    private static let bands: [(left: CGFloat, right: CGFloat, y: CGFloat)] = [
        (0.10, 0.76, 0.62),
        (0.28, 0.90, 0.74),
    ]
    private static let bandHeight: CGFloat = 0.08
    private static let gap: CGFloat = 0.03

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let originX = rect.midX - side / 2
        let originY = rect.midY - side / 2

        func pill(left: CGFloat, right: CGFloat, centerY: CGFloat, height: CGFloat) -> Path {
            let frame = CGRect(
                x: originX + left * side,
                y: originY + (centerY - height / 2) * side,
                width: (right - left) * side,
                height: height * side
            )
            return Path(roundedRect: frame, cornerRadius: frame.height / 2)
        }

        let sun = Self.sun
        var mark = Path(ellipseIn: CGRect(
            x: originX + (sun.x - sun.radius) * side,
            y: originY + (sun.y - sun.radius) * side,
            width: sun.radius * 2 * side,
            height: sun.radius * 2 * side
        ))
        for band in Self.bands {
            mark = mark.subtracting(pill(
                left: band.left - Self.gap,
                right: band.right + Self.gap,
                centerY: band.y,
                height: Self.bandHeight + Self.gap * 2
            ))
        }
        for band in Self.bands {
            mark = mark.union(pill(left: band.left, right: band.right, centerY: band.y, height: Self.bandHeight))
        }
        return mark
    }
}

/// Mark plus wordmark, used on the sign-in screen.
struct KasumiLogo: View {
    var markSize: CGFloat = 40

    var body: some View {
        HStack(spacing: markSize * 0.2) {
            KasumiMark()
                .fill(Brand.accent)
                .frame(width: markSize, height: markSize)
            Text("Kasumi")
                .font(.system(size: markSize * 0.7, weight: .medium))
                .foregroundStyle(Brand.textPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kasumi")
    }
}
