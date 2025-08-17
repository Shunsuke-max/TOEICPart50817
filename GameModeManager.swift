import Foundation

class GameModeManager {
    static let shared = GameModeManager()
    
    private let sprintLastPlayDateKey = "sprintLastPlayDateKey"
    private let survivalLastPlayDateKey = "survivalLastPlayDateKey"
    private let survivalLastAdPlayDateKey = "survivalLastAdPlayDateKey"
    private let timeAttackLastPlayDateKey = "timeAttackLastPlayDateKey"
    private let onimonSurvivalLastPlayDateKey = "onimonSurvivalLastPlayDateKey"
    
    enum Playability {
        case available
        case adAvailable // 広告を見ればプレイ可能
        case onCooldown  // 完全にプレイ不可
    }
    
    private init() {}
    
    /// Syntax Sprintをプレイできるかどうかを判定する
    func canPlaySyntaxSprint() -> Bool {
        return true // 常にプレイ可能にする
    }
    
    /// Syntax Sprintをプレイしたことを記録する
    func recordSyntaxSprintPlay() {
        // 何回でもプレイ可能にするため、記録ロジックを削除
    }
    
    func checkSurvivalPlayability() -> Playability {
        return .available
    }
    
    /// サバイバルモードをプレイしたことを記録する（通常プレイ）
    func recordSurvivalPlay() {
        // 何回でもプレイ可能にするため、記録ロジックを削除
    }
    
    /// 広告視聴によってサバイバルモードをプレイしたことを記録する
    func recordSurvivalAdPlay() {
        // 何回でもプレイ可能にするため、記録ロジックを削除
    }
    
    /// 鬼問サバイバルモードがアンロックされているかを判定する
    /// アンロック条件: Part 5 サバイバルで10問以上連続正解
    @MainActor func isOnimonSurvivalUnlocked() -> Bool {
        let normalSurvivalHighScore = UserStatsManager.shared.getSurvivalHighScore(for: .normal)
        return normalSurvivalHighScore >= 10
    }
    
    // ★★★ Time Attackのプレイ記録 ★★★
    func recordTimeAttackPlay() {
        UserDefaults.standard.set(Date(), forKey: "timeAttackLastPlayDateKey")
        print("INFO: Time Attackのプレイ日時を記録しました。")
    }
    
    // ★★★ 各モードのデイリークリア状況を判定する関数 ★★★
    func hasPlayedSyntaxSprintToday() -> Bool {
        guard let lastPlayDate = UserDefaults.standard.object(forKey: "sprintLastPlayDateKey") as? Date else { return false }
        return Calendar.current.isDateInToday(lastPlayDate)
    }
    
    func hasPlayedTimeAttackToday() -> Bool {
        guard let lastPlayDate = UserDefaults.standard.object(forKey: "timeAttackLastPlayDateKey") as? Date else { return false }
        return Calendar.current.isDateInToday(lastPlayDate)
    }
    
    func hasPlayedSurvivalToday() -> Bool {
        guard let lastPlayDate = UserDefaults.standard.object(forKey: "survivalLastPlayDateKey") as? Date else { return false }
        return Calendar.current.isDateInToday(lastPlayDate)
    }
    
    func hasPlayedOnimonSurvivalToday() -> Bool {
        guard let lastPlayDate = UserDefaults.standard.object(forKey: "onimonSurvivalLastPlayDateKey") as? Date else { return false }
        return Calendar.current.isDateInToday(lastPlayDate)
    }
    
    // ★★★ 鬼問サバイバルのプレイ記録 ★★★
    func recordOnimonSurvivalPlay() {
        UserDefaults.standard.set(Date(), forKey: "onimonSurvivalLastPlayDateKey")
        print("INFO: Onimon Survivalのプレイ日時を記録しました。")
    }
}
