import Foundation
import SwiftData

struct AchievementManager {
    
    static func checkAndAwardAchievements(context: ModelContext) -> [AchievementType]? {
        let unlockedIDs = fetchUnlockedAchievementIDs(context: context)
        var newAchievements: [AchievementType] = [] // 新しく解除されたものを保持する配列
        
        // 各実績タイプの条件をチェック
        for achievementType in AchievementType.allCases {
            guard !unlockedIDs.contains(achievementType.id) else { continue }
            
            let isAwarded = checkCondition(for: achievementType, context: context)
            
            if isAwarded {
                let newAchievement = UnlockedAchievement(id: achievementType.id, dateUnlocked: Date())
                context.insert(newAchievement)
                do {
                    try context.save() // データを永続化
                } catch {
                    print("❌ Failed to save UnlockedAchievement: \(error)")
                }
                print("🏆 Achievement Unlocked: \(achievementType.title)")
                newAchievements.append(achievementType) // 配列に追加
            }
        }
        
        // 新しく解除された実績がなければnil、あればその配列を返す
        return newAchievements.isEmpty ? nil : newAchievements
    }

    /// 解除済みの実績IDのセットを取得する
    private static func fetchUnlockedAchievementIDs(context: ModelContext) -> Set<String> {
        do {
            let descriptor = FetchDescriptor<UnlockedAchievement>()
            let unlocked = try context.fetch(descriptor)
            return Set(unlocked.map { $0.id })
        } catch {
            print("❌ Failed to fetch unlocked achievements: \(error)")
            return []
        }
    }
    
    /// 各実績の解除条件を判定する
    private static func checkCondition(for type: AchievementType, context: ModelContext) -> Bool {
        let allResults = fetchAllQuizResults(context: context)
        
        switch type {
        case .firstQuizCompleted:
            return !allResults.isEmpty
            
        case .tenQuizzesCompleted:
            return allResults.count >= 10
            
        case .perfectScore:
            return allResults.contains { $0.score > 0 && $0.score == $0.totalQuestions }
            
        case .mockTestCompleted:
            return allResults.contains { $0.setId == "mock_test" }
        case .anyQuizCompleted:
            return !allResults.isEmpty
        case .highAccuracyQuiz:
            return allResults.contains { $0.totalQuestions > 0 && (Double($0.score) / Double($0.totalQuestions)) >= 0.90 }
        case .sevenDayStreak:
            // TODO: Implement logic for sevenDayStreak achievement
            return false
        case .weaknessConquered:
            // TODO: Implement logic for weaknessConquered achievement
            return false
        case .dailyGoalAchieved:
            return true
        }
    }
    
    static func logMockTestCompletion(context: ModelContext) {
        // 模擬試験完了の実績をチェックし、必要であれば付与する
        _ = checkAndAwardAchievements(context: context)
    }
    
    static func logAnyQuizCompletion(context: ModelContext) {
        // 任意のクイズ完了の実績をチェックし、必要であれば付与する
        _ = checkAndAwardAchievements(context: context)
    }
    
    static func logQuizAccuracy(percentage: Double, context: ModelContext) {
        // 高精度クイズの実績をチェックし、必要であれば付与する
        _ = checkAndAwardAchievements(context: context)
    }
    
    static func logDailyGoalAchieved(context: ModelContext) {
        // 日次目標達成の実績をチェックし、必要であれば付与する
        _ = checkAndAwardAchievements(context: context)
    }
    
    /// 全てのクイズ結果を取得するヘルパー
    private static func fetchAllQuizResults(context: ModelContext) -> [QuizResult] {
        do {
            let descriptor = FetchDescriptor<QuizResult>()
            return try context.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch quiz results: \(error)")
            return []
        }
    }
}
