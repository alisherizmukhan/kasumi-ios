import Foundation
import Observation
import StoreKit

/// Loads products and runs purchases. Shared by the credits store and the Pro paywall.
@MainActor
@Observable
final class StoreViewModel {
    struct CompletedPurchase: Identifiable {
        let id = UUID()
        let product: StoreProduct
        let balance: Int
    }

    private(set) var products: [StoreProduct] = []
    private(set) var isLoading = false
    private(set) var purchasingID: String?
    private(set) var isRestoring = false
    var completedPurchase: CompletedPurchase?
    var errorMessage: String?

    @ObservationIgnored private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    var credits: Int { app.user?.credits ?? 0 }
    var isPro: Bool { app.user?.plan == .pro }
    var creditPacks: [StoreProduct] { products.filter { !$0.isSubscription } }
    var subscriptions: [StoreProduct] { products.filter(\.isSubscription) }

    /// "Save 33%" for the yearly plan compared with paying monthly.
    var yearlySavings: Int? {
        guard
            let monthly = subscriptions.first(where: { $0.kind == .subscription(.month) }),
            let yearly = subscriptions.first(where: { $0.kind == .subscription(.year) }),
            monthly.price > 0
        else { return nil }
        let ratio = NSDecimalNumber(decimal: yearly.price / (monthly.price * 12)).doubleValue
        let savings = Int(((1 - ratio) * 100).rounded())
        return savings > 0 ? savings : nil
    }

    func load() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        let storeKitProducts = (try? await Product.products(for: StoreCatalog.productIDs)) ?? []
        products = storeKitProducts.compactMap(StoreProduct.init(product:)).sorted { $0.price < $1.price }
        if products.isEmpty, DemoScreen.current != nil {
            products = StoreCatalog.demoProducts
        }
    }

    func buy(_ item: StoreProduct) async {
        purchasingID = item.id
        defer { purchasingID = nil }
        do {
            let user: User
            if let product = item.storeKitProduct {
                let result = try await product.purchase()
                guard case .success(let verification) = result else { return } // cancelled or pending
                let transaction = try verification.payloadValue
                // The backend verifies the transaction with the App Store and grants credits to the
                // account, so the balance is the same on web and mobile.
                user = try await app.backend.redeemPurchase(productID: transaction.productID, transactionID: transaction.id)
                await transaction.finish()
            } else {
                user = try await app.backend.redeemPurchase(productID: item.id, transactionID: 0)
            }
            app.updateUser(user)
            app.analytics.track(.purchaseCompleted(productID: item.id))
            completedPurchase = CompletedPurchase(product: item, balance: user.credits)
        } catch {
            errorMessage = error.localizedDescription
            app.crashReporter.record(error, context: "purchase")
        }
    }

    func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await app.refreshUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
