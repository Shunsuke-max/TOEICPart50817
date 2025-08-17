import Foundation

class SettingsManager {
    // アプリ内で常に同じインスタンスにアクセスするためのシングルトン
    static let shared = SettingsManager()
    
    // UserDefaultsにデータを保存するためのキー
    private let timerDurationKey = "timerDurationKey"
    private let hasCompletedOnboardingKey = "hasCompletedOnboardingKey"
    private let hasInteractedWithDiagnosticTestKey = "hasInteractedWithDiagnosticTestKey"
    private let isPremiumUserKey = "isPremiumUserKey"
    private let reminderEnabledKey = "isReminderEnabledKey"
    private let reminderHourKey = "reminderHourKey"
    private let reminderMinuteKey = "reminderMinuteKey"
    private let newMockTestNotificationKey = "newMockTestNotificationKey"
    private let hasCompletedInitialSetupKey = "hasCompletedInitialSetupKey"
    private let hasSeenInitialRecommendationKey = "hasSeenInitialRecommendationKey"
    private let dailyGoalKey = "dailyStudyGoalKey"
    private let areSoundEffectsEnabledKey = "areSoundEffectsEnabledKey"
    private let isBGMEnabledKey = "isBGMEnabledKey" // 新しく追加
    private let recommendedCourseIdKey = "recommendedCourseIdKey"
    private let lastReviewSessionDateKey = "lastReviewSessionDateKey"
    private let unlockedVocabularySetsKey = "unlockedVocabularySetsKey"
    private let hasTakenDiagnosticTestKey = "hasTakenDiagnosticTestKey"
    private let targetScoreKey = "targetScoreKey"

    
    // デフォルトのタイマー時間（秒）
    let defaultDuration = 20
    
    // 「タイマーなし」を意味する値
    let timerOffValue = 0
    
    // private initで外部からのインスタンス化を防ぐ
    private init() {}
    
    // 現在設定されているタイマー時間を取得・設定する
    var timerDuration: Int {
        get {
            // 値が保存されていなければ、デフォルト値を返す
            UserDefaults.standard.object(forKey: timerDurationKey) as? Int ?? defaultDuration
        }
        set {
            // 新しい値をUserDefaultsに保存する
            UserDefaults.standard.set(newValue, forKey: timerDurationKey)
        }
    }
    var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
        }
    }
    var hasInteractedWithDiagnosticTest: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasInteractedWithDiagnosticTestKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasInteractedWithDiagnosticTestKey)
        }
    }
    var isPremiumUser: Bool {
        get {
            // 開発・デバッグ用に常にtrueを返す
            return true
            // 本番環境では以下の行を使用
            // UserDefaults.standard.bool(forKey: isPremiumUserKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: isPremiumUserKey)
        }
    }
    var isReminderEnabled: Bool {
        get {
            // 値がなければデフォルトで有効(true)にする
            UserDefaults.standard.object(forKey: reminderEnabledKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reminderEnabledKey)
        }
    }
    
    /// ユーザーが設定したリマインダーの時間（時・分）
    var reminderTime: DateComponents {
        get {
            // 値がなければデフォルトで午前8時を返す
            let hour = UserDefaults.standard.object(forKey: reminderHourKey) as? Int ?? 8
            let minute = UserDefaults.standard.object(forKey: reminderMinuteKey) as? Int ?? 0
            return DateComponents(hour: hour, minute: minute)
        }
        set {
            // newValueにはDateComponentsが渡されることを想定
            UserDefaults.standard.set(newValue.hour, forKey: reminderHourKey)
            UserDefaults.standard.set(newValue.minute, forKey: reminderMinuteKey)
        }
    }
    
    var isNewMockTestNotificationEnabled: Bool {
        get {
            // デフォルトでは通知を有効(true)にしておく
            UserDefaults.standard.object(forKey: newMockTestNotificationKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: newMockTestNotificationKey)
        }
    }
    
    // ★★★ 1日の学習目標時間（秒単位）を取得・設定するプロパティ ★★★
    var dailyGoal: TimeInterval {
        get {
            // 値がなければデフォルトで30分 (1800秒) を返す
            UserDefaults.standard.object(forKey: dailyGoalKey) as? TimeInterval ?? 1800
        }
        set {
            UserDefaults.standard.set(newValue, forKey: dailyGoalKey)
        }
    }
    var hasCompletedInitialSetup: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedInitialSetupKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedInitialSetupKey)
        }
    }
    var hasSeenInitialRecommendation: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasSeenInitialRecommendationKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasSeenInitialRecommendationKey)
        }
    }

    var areSoundEffectsEnabled: Bool {
        get {
            // デフォルトはON(true)
            UserDefaults.standard.object(forKey: areSoundEffectsEnabledKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: areSoundEffectsEnabledKey)
        }
    }
    
    var isBGMEnabled: Bool {
        get {
            // デフォルトはON(true)
            UserDefaults.standard.object(forKey: isBGMEnabledKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: isBGMEnabledKey)
        }
    }
    
    var recommendedCourseId: String? {
            get {
                UserDefaults.standard.string(forKey: recommendedCourseIdKey)
            }
            set {
                UserDefaults.standard.set(newValue, forKey: recommendedCourseIdKey)
            }
        }
    var lastReviewSessionDate: Date? {
            get {
                UserDefaults.standard.object(forKey: lastReviewSessionDateKey) as? Date
            }
            set {
                UserDefaults.standard.set(newValue, forKey: lastReviewSessionDateKey)
            }
        }
    
    var unlockedVocabularySets: Set<String> {
        get {
            if let data = UserDefaults.standard.data(forKey: unlockedVocabularySetsKey), 
               let decodedSets = try? JSONDecoder().decode(Set<String>.self, from: data) {
                return decodedSets
            } else {
                // デフォルトで最初のセットをアンロック
                return ["VOCAB_600_SET_1"]
            }
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: unlockedVocabularySetsKey)
            }
        }
    }

    var hasTakenDiagnosticTest: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasTakenDiagnosticTestKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasTakenDiagnosticTestKey)
        }
    }

    var targetScore: String {
        get {
            UserDefaults.standard.string(forKey: targetScoreKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: targetScoreKey)
        }
    }

    func unlockNextVocabularySet(currentSetId: String, allSets: [VocabularyQuizSet]) {
        guard let currentIndex = allSets.firstIndex(where: { $0.setId == currentSetId }) else { return }
        
        let currentOrder = allSets[currentIndex].order
        
        // 次の順序のセットを探す
        if let nextSet = allSets.first(where: { $0.order == currentOrder + 1 }) {
            var currentUnlocked = unlockedVocabularySets
            if !currentUnlocked.contains(nextSet.setId) {
                currentUnlocked.insert(nextSet.setId)
                unlockedVocabularySets = currentUnlocked
                print("✅ Unlocked vocabulary set: \(nextSet.setName)")
            }
        }
    }
}
