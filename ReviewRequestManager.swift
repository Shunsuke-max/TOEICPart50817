import Foundation
import StoreKit

/// アプリ内レビュー依頼を管理するシングルトンクラス
enum ReviewRequestManager {
    
    private static let quizCompletionCountKey = "quizCompletionCount"
    
    /// クイズの完了回数を1つ増やす
    static func incrementCompletionCount() {
        var currentCount = UserDefaults.standard.integer(forKey: quizCompletionCountKey)
        currentCount += 1
        UserDefaults.standard.set(currentCount, forKey: quizCompletionCountKey)
        print("クイズ完了回数: \(currentCount)")
    }
    
    /// 条件を満たしていれば、アプリ内レビューを依頼する
    static func requestReviewIfAppropriate() {
        let currentCount = UserDefaults.standard.integer(forKey: quizCompletionCountKey)
        
        // クイズ完了回数が3回、15回、50回の時にレビューを依頼する
        let requestTimings = [3, 15, 50]
        
        guard requestTimings.contains(currentCount) else {
            return
        }
        
        // 現在アクティブなシーンを取得
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        // レビュー依頼を実行
        SKStoreReviewController.requestReview(in: scene)
        print("レビュー依頼を実行しました。 (完了回数: \(currentCount))")
    }
}
