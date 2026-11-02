import SwiftUI

/// Shown after a purchase goes through.
struct PurchaseSuccessView: View {
    let purchase: StoreViewModel.CompletedPurchase
    let onDone: @MainActor () -> Void

    private var product: StoreProduct { purchase.product }

    var body: some View {
        VStack(spacing: Theme.Space.xl) {
            Spacer(minLength: Theme.Space.xl)

            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Brand.onAccent)
                .frame(width: 56, height: 56)
                .background(Theme.accent, in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: Theme.Space.s) {
                Text(product.isSubscription ? "You're on Kasumi Pro" : "Payment complete")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            GroupedSection {
                ValueRow(title: product.displayName, value: product.displayPrice, mono: true)
                RowDivider()
                ValueRow(title: "Credits added", value: "+\(product.credits)", mono: true)
                RowDivider()
                ValueRow(title: "New balance", value: "\(purchase.balance)", mono: true)
            }

            Spacer(minLength: Theme.Space.xl)

            Button("Done", action: onDone)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Theme.Space.xl)
        .readableWidth(480)
        .screenBackground()
    }

    private var subtitle: String {
        switch product.kind {
        case .credits(let amount):
            "\(amount) credits are on your account and work on the web too"
        case .subscription(.month):
            "\(StoreCatalog.proMonthlyCredits) credits arrive every month. Your plan renews monthly until you cancel"
        case .subscription(.year):
            "\(StoreCatalog.proMonthlyCredits) credits arrive every month. Your plan renews yearly until you cancel"
        }
    }
}
