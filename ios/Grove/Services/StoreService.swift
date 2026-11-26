import Foundation
import StoreKit
import Observation

enum GroveProductID {
    static let lifetime = "com.grove.focus.lifetime"
}

@Observable
@MainActor
final class StoreService {
    private(set) var products: [Product] = []
    private(set) var isPurchasing = false
    private(set) var lastError: String?
    private(set) var hasLifetimeEntitlement = false

    private var updatesTask: Task<Void, Never>?

    func start() {
        updatesTask?.cancel()
        updatesTask = Task { await listenForTransactions() }
        Task {
            await refreshProducts()
            await refreshEntitlements()
        }
    }

    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    func refreshProducts() async {
        do {
            products = try await Product.products(for: [GroveProductID.lifetime])
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == GroveProductID.lifetime {
                unlocked = true
                await transaction.finish()
            }
        }
        hasLifetimeEntitlement = unlocked
    }

    func purchaseLifetime() async -> Bool {
        guard let product = products.first(where: { $0.id == GroveProductID.lifetime })
                ?? products.first else {
            lastError = String(localized: "Lifetime product unavailable. Check StoreKit config.")
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastError = String(localized: "Purchase could not be verified.")
                    return false
                }
                hasLifetimeEntitlement = true
                await transaction.finish()
                lastError = nil
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == GroveProductID.lifetime {
                hasLifetimeEntitlement = true
            }
            await transaction.finish()
        }
    }
}
