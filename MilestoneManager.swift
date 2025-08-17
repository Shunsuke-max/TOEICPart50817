import Foundation

/// 連続学習日数のマイルストーンと、その達成状況を管理するクラス
class MilestoneManager {
    
    static let shared = MilestoneManager()
    
    // マイルストーンの定義（日数と、お祝いメッセージ）
    let milestones: [(days: Int, message: String)] = [
        (3, "まずは3日達成！良いスタートです！"),
        (7, "7日間継続！学習が習慣になってきましたね！"),
        (14, "2週間達成！素晴らしい継続力です！"),
        (30, "1ヶ月継続！あなたの努力に敬意を表します！"),
        (50, "50日達成！もはや達人の域です！"),
        (100, "100日連続！伝説の始まりです！")
    ]
    
    private let awardedMilestonesKey = "awardedStreakMilestonesKey"
    
    private init() {}
    
    /// 新しいストリーク日数が、未達成のマイルストーンに到達したかチェックする
    /// - Parameter streakDays: 新しいストリーク日数
    /// - Returns: もし新しいマイルストーンを達成していれば、その情報を返す。なければnil。
    func checkAndAwardMilestone(for streakDays: Int) -> (days: Int, message: String)? {
        // 保存されている達成済みマイルストーン（日数）を読み込む
        var awardedDays = Set(UserDefaults.standard.array(forKey: awardedMilestonesKey) as? [Int] ?? [])
        
        // 定義されているマイルストーンの中で、現在のストリーク日数が達成しているものを探す
        guard let newMilestone = milestones.first(where: { $0.days == streakDays }) else {
            // 現在の日数がマイルストーンに一致しなければ、何もしない
            return nil
        }
        
        // そのマイルストーンが、まだ表彰されたことがないかチェック
        if !awardedDays.contains(newMilestone.days) {
            // 新しく達成したマイルストーンなので、記録に保存
            awardedDays.insert(newMilestone.days)
            UserDefaults.standard.set(Array(awardedDays), forKey: awardedMilestonesKey)
            
            print("🏆 新しいマイルストーンを達成: \(newMilestone.days)日")
            // 達成したマイルストーン情報を返す
            return newMilestone
        }
        
        // すでに表彰済みのマイルストーンなので、何もしない
        return nil
    }
}
