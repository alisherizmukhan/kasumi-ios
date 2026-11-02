import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class StoreViewModel {
    static let productIDs = ["kasumi.credits.100", "kasumi.credits.500", "kasumi.pro.monthly"]

    private(set) var products: [Product] = []
    private(set) var isLoading = true
    private(set) var purchasingID: String?
    var errorMessage: String?

    @ObservationIgnored private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    var credits: Int { app.user?.credits ?? 0 }

    func load() async {
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func buy(_ product: Product) async {
        purchasingID = product.id
        defer { purchasingID = nil }
        do {
            let result = try await product.purchase()
            guard case .success(let verification) = result else { return } // cancelled or pending
            let transaction = try verification.payloadValue
            // The backend verifies the transaction with the App Store and grants credits to the account,
            // so the balance is the same on web and mobile.
            let user = try await app.backend.redeemPurchase(productID: transaction.productID, transactionID: transaction.id)
            app.updateUser(user)
            await transaction.finish()
            app.analytics.track(.purchaseCompleted(productID: product.id))
        } catch {
            errorMessage = error.localizedDescription
            app.crashReporter.record(error, context: "purchase")
        }
    }
}
