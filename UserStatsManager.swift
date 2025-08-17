import Foundation
import Combine

/// ユーザーのレベルやXPなど、ゲーム的な統計情報を管理するクラス
@MainActor
class UserStatsManager: ObservableObject {
    
    static let shared = UserStatsManager()
    
    // 変更をUIに通知するためのPublisher
    let statsChanged = PassthroughSubject<Void, Never>()
    
    // UserDefaults用のキー
    private let userLevelKey = "userLevelKey"
    private let currentXPKey = "currentXPKey"
    private let sprintHighScoreKey = "sprintHighScoreKey"
    private let sprintMaxComboKey = "sprintMaxComboKey"
    private let survivalHighScoreKey = "survivalHighScoreKey"
    private let onimonSurvivalHighScoreKey = "onimonSurvivalHighScoreKey"
    private let onimonSurvivalUnlockedKey = "onimonSurvivalUnlockedKey" // ★★★ 追加 ★★★
    private let timeAttackHighScoreKey = "timeAttackHighScoreKey" // ★★★ 追加 ★★★

    private init() {}
    
    // MARK: - Public Getters
    
    var userLevel: Int {
        // 保存されていなければレベル1からスタート
        UserDefaults.standard.object(forKey: userLevelKey) as? Int ?? 1
    }
    
    var currentXP: Int {
        UserDefaults.standard.integer(forKey: currentXPKey)
    }
    
    /// 次のレベルアップに必要なXPを計算する
    func getXPForNextLevel() -> Int {
        // レベルが上がるごとに必要XPが増える単純な計算式
        // 例: Lv1→2は100XP, Lv2→3は200XP...
        return userLevel * 100
    }
    
    /// レベルに応じたTOEICスコアの目安を返す
    func getToeicScoreEstimate(forLevel level: Int) -> String {
        switch level {
        case 1...5:
            return "スコア目安: 350-450点"
        case 6...10:
            return "スコア目安: 450-550点"
        case 11...15:
            return "スコア目安: 550-650点"
        case 16...20:
            return "スコア目安: 650-750点"
        case 21...25:
            return "スコア目安: 750-850点"
        case 26...30:
            return "スコア目安: 850-950点"
        case 31...:
            return "スコア目安: 950-990点"
        default:
            return "測定中"
        }
    }
    
    // MARK: - Public Methods

    func addXP(_ points: Int) -> Bool {
            var newXP = currentXP + points
            let requiredXP = getXPForNextLevel()
            var didLevelUp = false // ★追加: レベルアップしたかを記録する変数
            
            // レベルアップ処理
            if newXP >= requiredXP {
                let newLevel = userLevel + 1
                // レベルを保存
                UserDefaults.standard.set(newLevel, forKey: userLevelKey)
                // 余ったXPを次のレベルに持ち越す
                newXP -= requiredXP
                print("🏆 LEVEL UP! You are now Level \(newLevel)!")
                didLevelUp = true // ★追加: レベルアップしたことを記録
            }
            
            // 新しいXPを保存
            UserDefaults.standard.set(newXP, forKey: currentXPKey)
            print("✅ Added \(points) XP. Total XP is now \(newXP).")
            
            // 変更を通知
            statsChanged.send()
            
            // ★変更点: レベルアップしたかどうかを返す
            return didLevelUp
        }
    func getSyntaxSprintRecord() -> (highScore: Int, maxCombo: Int) {
            let highScore = UserDefaults.standard.integer(forKey: sprintHighScoreKey)
            let maxCombo = UserDefaults.standard.integer(forKey: sprintMaxComboKey)
            return (highScore, maxCombo)
        }
        
        /// Syntax Sprintの新しい記録を更新する
        /// - Returns: ハイスコアが更新されたかどうかをBool値で返す
        func updateSyntaxSprint(newScore: Int, newMaxCombo: Int) -> Bool {
            let currentRecord = getSyntaxSprintRecord()
            var isNewRecord = false
            
            if newScore > currentRecord.highScore {
                UserDefaults.standard.set(newScore, forKey: sprintHighScoreKey)
                isNewRecord = true
            }
            
            if newMaxCombo > currentRecord.maxCombo {
                UserDefaults.standard.set(newMaxCombo, forKey: sprintMaxComboKey)
                // スコアが更新されていなくても、コンボ更新で新記録と見なす場合
                isNewRecord = true
            }
            
            return isNewRecord
        }
    
    func getSurvivalHighScore(for type: SurvivalViewModel.SurvivalType) -> Int {
        switch type {
        case .normal:
            return UserDefaults.standard.integer(forKey: survivalHighScoreKey)
        case .onimon:
            return UserDefaults.standard.integer(forKey: onimonSurvivalHighScoreKey)
        }
    }
        
    /// サバイバルモードのハイスコアを更新する
    func updateSurvivalHighScore(newScore: Int, for type: SurvivalViewModel.SurvivalType) {
        let currentHighScore = getSurvivalHighScore(for: type)
        if newScore > currentHighScore {
            switch type {
            case .normal:
                UserDefaults.standard.set(newScore, forKey: survivalHighScoreKey)
                // ★★★ アンロック条件をチェック ★★★
                if newScore >= 10 {
                    unlockOnimonSurvival()
                }
            case .onimon:
                UserDefaults.standard.set(newScore, forKey: onimonSurvivalHighScoreKey)
            }
            print("🏆 New Survival High Score for \(type): \(newScore)")
            // ここで新記録を通知する仕組みを追加することも可能
        }
    }
    
    /// Time Attackのハイスコアを取得する
    func getTimeAttackHighScore() -> Int {
        UserDefaults.standard.integer(forKey: timeAttackHighScoreKey)
    }
    
    /// Time Attackのハイスコアを更新する
    func updateTimeAttackHighScore(newScore: Int) {
        let currentHighScore = getTimeAttackHighScore()
        if newScore > currentHighScore {
            UserDefaults.standard.set(newScore, forKey: timeAttackHighScoreKey)
            print("🏆 New Time Attack High Score: \(newScore)")
        }
    }

    // ★★★ 鬼問サバイバルをアンロックする ★★★
    private func unlockOnimonSurvival() {
        UserDefaults.standard.set(true, forKey: onimonSurvivalUnlockedKey)
        print("🎉 UNLOCKED: Onimon Survival Mode!")
    }
    }
