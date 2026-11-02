import Foundation
import StoreKit

/// A credit pack or subscription as the UI sees it. Backed by a StoreKit `Product`,
/// or by the demo catalog when the app runs without a StoreKit configuration (CI screenshots).
struct StoreProduct: Identifiable, Sendable {
    enum Kind: Sendable, Equatable {
        case credits(Int)
        case subscription(Period)
    }

    enum Period: Sendable, Equatable {
        case month, year
    }

    let id: String
    let displayName: String
    let description: String
    let displayPrice: String
    let price: Decimal
    let currencyCode: String
    let locale: Locale
    let kind: Kind
    /// nil for demo products: their purchase goes straight to the backend.
    let storeKitProduct: Product?

    var isSubscription: Bool {
        if case .subscription = kind { return true }
        return false
    }

    /// Credits this purchase adds right away.
    var credits: Int {
        switch kind {
        case .credits(let amount): amount
        case .subscription: StoreCatalog.proMonthlyCredits
        }
    }

    func formatted(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: currencyCode).locale(locale))
    }
}

extension StoreProduct {
    init?(product: Product) {
        guard let kind = StoreCatalog.kinds[product.id] else { return nil }
        self.init(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice,
            price: product.price,
            currencyCode: product.priceFormatStyle.currencyCode,
            locale: product.priceFormatStyle.locale,
            kind: kind,
            storeKitProduct: product
        )
    }
}

enum StoreCatalog {
    static let proMonthlyCredits = 300

    static let kinds: [String: StoreProduct.Kind] = [
        "kasumi.credits.100": .credits(100),
        "kasumi.credits.500": .credits(500),
        "kasumi.pro.monthly": .subscription(.month),
        "kasumi.pro.yearly": .subscription(.year),
    ]

    static var productIDs: [String] { Array(kinds.keys) }

    /// Same products as `StoreKit/Products.storekit`, used only in demo mode.
    static let demoProducts: [StoreProduct] = [
        demo("kasumi.credits.100", "100 credits", "Enough for 5 to 10 videos", 4.99),
        demo("kasumi.credits.500", "500 credits", "For people who post every day", 19.99),
        demo("kasumi.pro.monthly", "Kasumi Pro", "300 credits every month and priority rendering", 9.99),
        demo("kasumi.pro.yearly", "Kasumi Pro, yearly", "300 credits every month and priority rendering", 79.99),
    ]

    private static func demo(_ id: String, _ name: String, _ description: String, _ price: Decimal) -> StoreProduct {
        let locale = Locale(identifier: "en_US")
        return StoreProduct(
            id: id,
            displayName: name,
            description: description,
            displayPrice: price.formatted(.currency(code: "USD").locale(locale)),
            price: price,
            currencyCode: "USD",
            locale: locale,
            kind: kinds[id]!,
            storeKitProduct: nil
        )
    }
}
