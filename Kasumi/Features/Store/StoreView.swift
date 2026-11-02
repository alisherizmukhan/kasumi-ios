import StoreKit
import SwiftUI

struct StoreView: View {
    @State private var viewModel: StoreViewModel

    init(app: AppModel) {
        _viewModel = State(initialValue: StoreViewModel(app: app))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text("\(viewModel.credits)")
                        .font(.system(size: 40, weight: .medium).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: Double(viewModel.credits)))
                    Text("Credits on your account")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, Theme.Space.l)
                .animation(Theme.ease(0.3), value: viewModel.credits)

                GroupedSection(
                    header: "Top up",
                    footer: "Payments go through Apple. Credits are added to your Kasumi account and work on the web too."
                ) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 96)
                    } else if viewModel.products.isEmpty {
                        ContentUnavailableView(
                            "Store unavailable",
                            systemImage: "cart",
                            description: Text("Run from Xcode with Products.storekit to test purchases")
                        )
                    } else {
                        ForEach(Array(viewModel.products.enumerated()), id: \.element.id) { index, product in
                            if index > 0 { RowDivider() }
                            productRow(product)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.vertical, Theme.Space.s)
        }
        .screenBackground()
        .navigationTitle("Buy credits")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .errorAlert($viewModel.errorMessage)
    }

    private func productRow(_ product: Product) -> some View {
        HStack(spacing: Theme.Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(product.description)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                Task { await viewModel.buy(product) }
            } label: {
                if viewModel.purchasingID == product.id {
                    ProgressView()
                } else {
                    Text(product.displayPrice).monospacedDigit()
                }
            }
            .buttonStyle(SecondaryButtonStyle(height: 36))
            .frame(width: 96)
            .disabled(viewModel.purchasingID != nil)
        }
        .padding(Theme.Space.l)
    }
}
