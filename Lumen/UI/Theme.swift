import SwiftUI

enum Theme {
    static var accent: Color { Color(red: 0.66, green: 0.45, blue: 1.0) }
    static var accentSecondary: Color { Color(red: 1.0, green: 0.42, blue: 0.62) }
    static var card: Color { Color.white.opacity(0.07) }
    static var cardBorder: Color { Color.white.opacity(0.12) }

    static var gradient: LinearGradient {
        LinearGradient(colors: [accent, accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
