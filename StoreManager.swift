import Foundation
import StoreKit

// 購入可能な製品と、購入済みアイテムを管理する
@MainActor
class StoreManager: ObservableObject {

    static let shared = StoreManager()

    // 広告除去アイテムのプロダクトID
    let productID = "com.yourcompany.appname.removeads" // ★ ステップ1で設定したIDに置き換える

    @Published var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    
    var transactionListener: Task<Void, Error>? = nil

    private init() {
        // アプリ起動時にトランザクションのリスナーを開始
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedStatus()
                    await transaction.finish()
                } catch {
                    print("❌ Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }

    // App Storeから製品情報を取得する
    func fetchProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            self.products = products
        } catch {
            print("❌ Failed to fetch products: \(error)")
        }
    }

    // 指定された製品の購入処理を開始する
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedStatus()
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    // 過去の購入情報を復元する
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedStatus()
    }

    // 購入済みかどうかのステータスを更新する
    func updatePurchasedStatus() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
        
        // 永続化層にも反映
        SettingsManager.shared.isPremiumUser = !self.purchasedProductIDs.isEmpty
    }
    
    // トランザクションがAppleによって署名されているか検証する
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unknown
        case .verified(let safe):
            return safe
        }
    }
}
