import StoreKit
import SwiftUI

struct StoreView: View {
    @State private var viewModel: StoreViewModel

    init(app: AppModel) {
        _viewModel = State(initialValue: StoreViewModel(app: app))
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 6) {
                    Text("\(viewModel.credits)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: Double(viewModel.credits)))
                    Text("credits available")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .animation(.snappy, value: viewModel.credits)
            }

            Section("Top up") {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if viewModel.products.isEmpty {
                    ContentUnavailableView(
                        "Store unavailable",
                        systemImage: "cart",
                        description: Text("Run from Xcode with Products.storekit to test purchases.")
                    )
                } else {
                    ForEach(viewModel.products, id: \.id) { product in
                        productRow(product)
                    }
                }
            }

            Section {
            } footer: {
                Text("Payments are processed by Apple. Credits are added to your account and work on the web too.")
            }
        }
        .navigationTitle("Get credits")
        .task { await viewModel.load() }
        .errorAlert($viewModel.errorMessage)
    }

    private func productRow(_ product: Product) -> some View {
        HStack(spacing: 14) {
            Image(systemName: product.type == .autoRenewable ? "crown.fill" : "bolt.fill")
                .font(.title2)
                .foregroundStyle(Theme.gradient)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName).font(.headline)
                Text(product.description).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await viewModel.buy(product) }
            } label: {
                if viewModel.purchasingID == product.id {
                    ProgressView()
                } else {
                    Text(product.displayPrice).bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.purchasingID != nil)
        }
        .padding(.vertical, 4)
    }
}
