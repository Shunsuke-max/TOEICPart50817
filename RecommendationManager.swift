import Foundation
import SwiftData

/// ユーザーの学習履歴を分析し、最適な学習コースを推薦するためのロジックを管理する
struct RecommendationManager {

    /// 実力診断テストの結果を分析し、最も苦手だったコースを返す
    /// - Parameter context: SwiftDataのコンテキスト
    /// - Returns: 最も苦手と判断されたCourseオブジェクト。診断テスト未受験、または分析不要の場合はnil。
    static func generateRecommendation(context: ModelContext) async -> Course? {
        do {
            // --- 1. SwiftDataから全クイズ結果を取得 ---
            let allResultsDescriptor = FetchDescriptor<QuizResult>()
            let allResults = try context.fetch(allResultsDescriptor)
            
            // --- 2. 実力診断テストの結果を探す ---
            guard let diagnosticResult = allResults.first(where: { $0.setId == "DIAGNOSTIC_TEST" }) else {
                print("ℹ️ 実力診断テストの結果が見つからないため、レコメンドをスキップします。")
                return nil
            }
            
            // --- 3. 間違えた問題のIDリストを取得 ---
            let incorrectIDs = diagnosticResult.incorrectQuestionIDs
            guard !incorrectIDs.isEmpty else {
                print("ℹ️ 実力診断テストで全問正解のため、レコメンドは不要です。")
                // 全問正解したことを記録し、次回以降表示しないようにする
                SettingsManager.shared.hasSeenInitialRecommendation = true
                return nil
            }
            
            // --- 4. 全コースのデータを取得 ---
            let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
            
            // --- 5. 間違えた問題がどのコースに属するかを特定し、集計 ---
            var courseErrorCounts: [String: Int] = [:] // [コースID: 間違い回数]
            
            for course in allCourses {
                for quizSet in course.quizSets {
                    for question in quizSet.questions {
                        if incorrectIDs.contains(question.id) {
                            // この問題が属するコースの間違いカウントを増やす
                            courseErrorCounts[course.id, default: 0] += 1
                        }
                    }
                }
            }
            
            // --- 6. 最も間違いが多かったコースIDを特定 ---
            guard let weakestCourseID = courseErrorCounts.max(by: { $0.value < $1.value })?.key else {
                return nil
            }
            
            print("🏆 分析の結果、最も苦手なコースは \(weakestCourseID) と判断されました。")
            // --- 7. IDを元に、完全なCourseオブジェクトを返却 ---
            return allCourses.first(where: { $0.id == weakestCourseID })
            
        } catch {
            print("❌ レコメンド生成中にエラーが発生しました: \(error)")
            return nil
        }
    }
}
