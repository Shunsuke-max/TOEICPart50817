import Foundation
import SwiftData

/// ユーザーが解除した実績をSwiftDataで永続化するためのモデル
@Model
final class UnlockedAchievement {
    // AchievementTypeのrawValueをユニークIDとして使用
    @Attribute(.unique) var id: String
    
    // 実績を解除した日付
    var dateUnlocked: Date

    init(id: String, dateUnlocked: Date) {
        self.id = id
        self.dateUnlocked = dateUnlocked
    }
}
