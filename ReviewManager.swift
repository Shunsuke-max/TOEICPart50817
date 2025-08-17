import Foundation
import SwiftData

@MainActor // このクラスのメソッドはすべてメインスレッドで実行されるようにマークします
class ReviewManager {
    
    /// SM-2アルゴリズムに基づいて復習アイテムを更新する
    /// - Parameters:
    ///   - questionID: 復習対象の問題ID
    ///   - quality: ユーザーの回答の質 (0-5):
    ///     0: 全く思い出せない (Hardest)
    ///     1: 間違えたが、正解を見るとわかる
    ///     2: 間違えたが、少し考えればわかる
    ///     3: 正解したが、自信がない
    ///     4: 正解した (Easy)
    ///     5: 完璧に正解した (Easiest)
    ///   - modelContext: SwiftDataのModelContext
    func updateReviewItem(questionID: String, quality: Int, modelContext: ModelContext) async {
        do {
            // 復習対象の問題IDに一致するReviewItemを検索するための準備
            let predicate = #Predicate<ReviewItem> { $0.questionID == questionID }
            var descriptor = FetchDescriptor(predicate: predicate)
            descriptor.fetchLimit = 1 // 一致するものは1つだけあればよい
            
            // ModelContextへのアクセスをメインスレッドで行うように保証し、データを取得
            let existingItems = try await MainActor.run {
                try modelContext.fetch(descriptor) // fetchはthrowsする可能性があるためtryが必要
            }
            
            let item: ReviewItem
            if let existingItem = existingItems.first {
                // 既存のアイテムがあればそれを使用
                item = existingItem
            } else {
                // 既存のアイテムがない場合、新しいアイテムを作成
                item = ReviewItem(questionID: questionID, lastReviewed: Date(), nextReview: Date(), repetition: 0, easeFactor: 2.5, lastInterval: 0)
                // 新しいアイテムをModelContextに挿入する処理もメインスレッドで行う
                await MainActor.run {
                    modelContext.insert(item) // insertはthrowsしないが、念のためMainActor.run内で実行
                }
            }
            
            // SM-2アルゴリズムによる復習スケジュールの計算
            var newRepetition = item.repetition
            var newEaseFactor = item.easeFactor
            var newInterval: TimeInterval = 0 // 秒単位で計算
            
            if quality >= 3 { // 正解の場合 (Quality >= 3)
                newRepetition += 1 // 復習回数を増やす
                // Ease Factorを更新 (回答の質に応じて調整)
                newEaseFactor = newEaseFactor + (0.1 - (5 - Double(quality)) * (0.08 + (5 - Double(quality)) * 0.02))
                if newEaseFactor < 1.3 { newEaseFactor = 1.3 } // Ease Factorの最小値を1.3に制限
                
                // 次の復習間隔を決定
                switch newRepetition {
                case 1:
                    newInterval = 1 * 24 * 60 * 60 // 1日後 (24時間 * 60分 * 60秒)
                case 2:
                    newInterval = 6 * 24 * 60 * 60 // 6日後
                default:
                    // 前回の復習間隔が記録されていれば、それを基に計算
                    newInterval = item.lastInterval * newEaseFactor
                }
            } else { // 不正解の場合 (Quality < 3)
                newRepetition = 0 // 復習回数をリセット
                newInterval = 1 * 24 * 60 * 60 // 次回は1日後に復習
            }
            
            // 次回復習日を計算
            let calendar = Calendar.current
            // 現在の日付に計算した間隔を加算して次回復習日を決定
            let nextReviewDate = calendar.date(byAdding: .second, value: Int(newInterval), to: Date()) ?? Date()
            
            // アイテムのプロパティを更新
            item.lastReviewed = Date() // 今回の復習日時を記録
            item.nextReview = nextReviewDate // 次回の復習日時を設定
            item.repetition = newRepetition // 更新された復習回数を記録
            item.easeFactor = newEaseFactor // 更新されたEase Factorを記録
            item.lastInterval = newInterval // 更新された最後の間隔を記録
            
            // 更新したアイテムをModelContextに保存 (メインスレッドで行い、エラーハンドリングも行う)
            do {
                try await MainActor.run {
                    try modelContext.save() // save()はthrowsするので、ここにもtryが必要
                }
                // 保存が成功した場合のログ出力
                print("ReviewItem for \(questionID) updated. Next review: \(item.nextReview), Repetition: \(item.repetition), EaseFactor: \(item.easeFactor), Interval: \(newInterval / (24*60*60)) days")
            } catch {
                // 保存に失敗した場合のエラーハンドリング
                print("Failed to update ReviewItem with SM-2: \(error)")
            }
            
        } catch {
            // 上記のdoブロック全体でエラーが発生した場合のハンドリング
            print("Failed to update ReviewItem with SM-2: \(error)")
        }
    }
    
    /// 特定のquestionIDの復習アイテムが存在するか確認する
    func reviewItemExists(questionID: String, modelContext: ModelContext) async -> Bool {
        do {
            // 質問IDで検索するための準備
            let predicate = #Predicate<ReviewItem> { $0.questionID == questionID }
            var descriptor = FetchDescriptor(predicate: predicate)
            descriptor.fetchLimit = 1 // 1つ見つかれば十分
            
            // ModelContextからアイテムの数を取得 (メインスレッドで行い、エラーハンドリングも行う)
            let count = try await MainActor.run {
                try modelContext.fetchCount(descriptor) // fetchCountはthrowsするのでtryが必要
            }
            // 見つかったアイテム数が0より多ければ存在する
            return count > 0
        } catch {
            // エラー発生時のハンドリング
            print("Failed to check ReviewItem existence: \(error)")
            return false
        }
    }
    
    /// 全ての復習アイテムを取得する (デバッグ用など)
    func fetchAllReviewItems(modelContext: ModelContext) async -> [ReviewItem] {
        do {
            // ModelContextから全てのReviewItemを取得 (メインスレッドで行い、エラーハンドリングも行う)
            return try await MainActor.run {
                try modelContext.fetch(FetchDescriptor<ReviewItem>()) // fetchはthrowsするのでtryが必要
            }
        } catch {
            // エラー発生時のハンドリング
            print("Failed to fetch all ReviewItems: \(error)")
            return []
        }
    }
    
    /// 今日復習すべきアイテムの数を取得する
    func getTodaysReviewCount(modelContext: ModelContext) async -> Int {
        do {
            // 今日の0時を取得
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // 今日以前にレビュー予定のアイテムを検索するための準備
            let predicate = #Predicate<ReviewItem> { item in
                item.nextReview <= today // 次回の復習日が今日以前の場合
            }
            let descriptor = FetchDescriptor(predicate: predicate)
            
            // ModelContextから該当するアイテムの数を取得 (メインスレッドで行い、エラーハンドリングも行う)
            return try await MainActor.run {
                try modelContext.fetchCount(descriptor) // fetchCountはthrowsするのでtryが必要
            }
        } catch {
            // エラー発生時のハンドリング
            print("Failed to fetch today's review count: \(error)")
            return 0
        }
    }
    
    /// 指定されたquestionIDの復習アイテムを削除する
    func deleteReviewItem(questionID: String, modelContext: ModelContext) async {
        do {
            let predicate = #Predicate<ReviewItem> { $0.questionID == questionID }
            let descriptor = FetchDescriptor(predicate: predicate)
            
            // ↓↓↓ 修正箇所 ↓↓↓
            // MainActor.run を削除し、直接 try await で fetch を呼び出す
            if let existingItem = try await modelContext.fetch(descriptor).first {
                
                // delete は throws しないので try は不要ですが、MainActorで行う
                await MainActor.run {
                    modelContext.delete(existingItem)
                }
                
                // save は throws するので try await を使い、do-catch で囲む
                do {
                    try await modelContext.save()
                    print("ReviewItem for \(questionID) deleted.")
                } catch {
                    print("Failed to save after deleting ReviewItem: \(error)")
                }
            } else {
                // アイテムが見つからなかった場合
                print("ReviewItem with ID \(questionID) not found for deletion.")
            }
        } catch {
            // fetch処理中にエラーが発生した場合のハンドリング
            print("Failed to delete ReviewItem: \(error)")
        }
    }
}
