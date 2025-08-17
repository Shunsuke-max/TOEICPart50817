import Foundation
import FirebaseFirestore

/// コンテンツ評価（マイクロサーベイ）の管理を行うシングルトンクラス
@MainActor
class FeedbackManager {
    static let shared = FeedbackManager()
    
    private let db = Firestore.firestore()
    private let quizCompletionCountKey = "quizCompletionCountForSurvey"

    private init() {}
    
    /// クイズの完了回数を記録し、サーベイを表示すべきか判断する
    func checkAndTriggerSurvey() -> Bool {
        var currentCount = UserDefaults.standard.integer(forKey: quizCompletionCountKey)
        currentCount += 1
        UserDefaults.standard.set(currentCount, forKey: quizCompletionCountKey)
        
        // 5回完了するごとにサーベイの表示を試みる
        if currentCount % 5 == 0 {
            print("サーベイ表示のタイミングです。")
            return true
        }
        return false
    }
    
    /// クイズセットへの評価をFirestoreに送信する
    /// - Parameters:
    ///   - quizSetId: 評価対象のクイズセットID
    ///   - wasHelpful: 役に立ったかどうか (true/false)
    func submitQuizSetFeedback(quizSetId: String, wasHelpful: Bool) {
        let collectionRef = db.collection("feedback")
        
        let data: [String: Any] = [
            "quizSetId": quizSetId,
            "wasHelpful": wasHelpful,
            "timestamp": Timestamp(date: Date())
        ]
        
        collectionRef.addDocument(data: data) { error in
            if let error = error {
                print("❌ Firestoreへのフィードバック送信に失敗しました: \(error)")
            } else {
                print("✅ フィードバックが正常に送信されました。")
            }
        }
    }
}
