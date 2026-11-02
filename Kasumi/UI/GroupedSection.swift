import SwiftUI

/// A grouped card with an optional sentence-case header and footer.
/// Used instead of `List` sections, whose system headers are always uppercased.
/// Put a `RowDivider()` between rows.
struct GroupedSection<Content: View>: View {
    var header: String?
    var footer: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if let header {
                Text(header)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Theme.Space.l)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) {
                content
            }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).strokeBorder(Theme.hairline))
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, Theme.Space.l)
            }
        }
    }
}

struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
            .padding(.leading, Theme.Space.l)
    }
}

/// A title and value in one row of a grouped section.
struct ValueRow: View {
    let title: String
    let value: String
    var mono = false

    var body: some View {
        HStack {
            Text(title).foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(value)
                .font(mono ? .body.monospacedDigit() : .body)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, Theme.Space.l)
        .frame(minHeight: 48)
        .accessibilityElement(children: .combine)
    }
}
