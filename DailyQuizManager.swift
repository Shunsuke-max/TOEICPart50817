/*
import Foundation
import UIKit

class DailyQuizManager {
    static let shared = DailyQuizManager()
    
    // MARK: - UserDefaults Keys
    private let shuffledIDsKey = "dailyQuizShuffledIDsKey"
    private let currentIndexKey = "dailyQuizCurrentIndexKey"
    private let lastAttemptDateKey = "dailyQuizLastAttemptDateKey"
    private let attemptResultsKey = "dailyQuizResultsKey"
    private let streakCountKey = "dailyQuizStreakCountKey"
    private let lastCorrectDateKey = "dailyQuizLastCorrectDateKey"
    private let longestStreakCountKey = "dailyQuizLongestStreakCountKey"

    enum State {
        case notAttempted
        case attemptedAndCorrect
        case attemptedAndIncorrect
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    func scheduleDailyNotification() {
        // ... (この関数は変更なし)
        let center = UNUserNotificationCenter.current()
        let notificationId = "dailyQuizNotification"
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        guard SettingsManager.shared.isReminderEnabled else {
            print("ℹ️ Daily reminder is disabled. Notification cancelled.")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "今日の一問の時間です！"
        content.body = "今日の問題に挑戦して、英語力をアップさせましょう！"
        content.sound = .default
        var dateComponents = SettingsManager.shared.reminderTime
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("❌ Notification scheduling error: \(error.localizedDescription)")
            } else {
                print("✅ Daily notification scheduled for \(dateComponents.hour!):\(String(format: "%02d", dateComponents.minute!)).")
            }
        }
    }
    
    /// 今日の問題を取得します。必要に応じて、日付の更新処理も行います。
    func fetchTodaysQuestion() async -> Question? {
        // 最初のリスト準備がまだなら実行
        if UserDefaults.standard.array(forKey: shuffledIDsKey) == nil {
            guard await prepareShuffledList() else {
                print("❌ Daily quiz list preparation failed. Cannot fetch question.")
                return nil
            }
        }
        
        // 日付が変わっていれば、次の問題へインデックスを進める
        if let lastDate = UserDefaults.standard.object(forKey: lastAttemptDateKey) as? Date {
            if !Calendar.current.isDateInToday(lastDate) {
                advanceToNextQuestion()
            }
        }
        
        // 今日の問題IDを取得
        guard let allIDs = UserDefaults.standard.stringArray(forKey: shuffledIDsKey) else { return nil }
        let currentIndex = UserDefaults.standard.integer(forKey: currentIndexKey)
        
        guard allIDs.indices.contains(currentIndex) else {
            print("⚠️ Daily quiz index out of bounds. Reshuffling...")
            guard await prepareShuffledList() else { return nil }
            return await fetchTodaysQuestion() // 再度試行
        }
        
        let todaysID = allIDs[currentIndex]
        // IDを元に問題を探す
        return await findQuestion(withID: todaysID)
    }
    
    func recordAttempt(wasCorrect: Bool) {
        // ... (この関数は変更なし)
        let today = Date()
        UserDefaults.standard.set(today, forKey: lastAttemptDateKey)
        var results = UserDefaults.standard.dictionary(forKey: attemptResultsKey) as? [String: Bool] ?? [:]
        let dateString = dateToString(today)
        results[dateString] = wasCorrect
        UserDefaults.standard.set(results, forKey: attemptResultsKey)
        print("Daily quiz attempt recorded. Correct: \(wasCorrect)")
        var currentStreak = UserDefaults.standard.integer(forKey: streakCountKey)
        if wasCorrect {
            if let lastCorrect = UserDefaults.standard.object(forKey: lastCorrectDateKey) as? Date {
                guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return }
                if Calendar.current.isDate(lastCorrect, inSameDayAs: yesterday) {
                    currentStreak += 1
                } else if !Calendar.current.isDateInToday(lastCorrect) {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            UserDefaults.standard.set(today, forKey: lastCorrectDateKey)
        } else {
            currentStreak = 0
        }
        UserDefaults.standard.set(currentStreak, forKey: streakCountKey)
        print("🔥 New streak count: \(currentStreak)")
        let longestStreak = getLongestStreakCount()
        if currentStreak > longestStreak {
            UserDefaults.standard.set(currentStreak, forKey: longestStreakCountKey)
            print("🏆 New longest streak record: \(currentStreak) days!")
        }
        let key = "hasScheduledDailyNotification"
        if !UserDefaults.standard.bool(forKey: key) {
            scheduleDailyNotification()
            UserDefaults.standard.set(true, forKey: key)
        }
    }
    
    func getStreakCount() -> Int {
        return UserDefaults.standard.integer(forKey: streakCountKey)
    }
    
    func getLongestStreakCount() -> Int {
        return UserDefaults.standard.integer(forKey: longestStreakCountKey)
    }
    
    func getTodaysState() -> State {
        // ... (この関数は変更なし)
        guard let lastDate = UserDefaults.standard.object(forKey: lastAttemptDateKey) as? Date,
              Calendar.current.isDateInToday(lastDate) else {
            return .notAttempted
        }
        let results = UserDefaults.standard.dictionary(forKey: attemptResultsKey) as? [String: Bool] ?? [:]
        let dateString = dateToString(Date())
        if let wasCorrect = results[dateString] {
            return wasCorrect ? .attemptedAndCorrect : .attemptedAndIncorrect
        }
        return .notAttempted
    }
    
    // MARK: - Private Helper Methods
    
    /// ★★★ DataServiceのキャッシュ機能を使うように修正 ★★★
    private func prepareShuffledList() async -> Bool {
        do {
            // 新しいキャッシュ対応の関数を呼び出す
            let allQuestions = try await DataService.shared.getAllQuestions()
            let allQuestionIDs = allQuestions.map { $0.id }.shuffled()
            
            UserDefaults.standard.set(allQuestionIDs, forKey: shuffledIDsKey)
            UserDefaults.standard.set(0, forKey: currentIndexKey)
            print("✅ Daily quiz list prepared with \(allQuestionIDs.count) questions.")
            return true
        } catch {
            print("❌ Failed to prepare daily quiz list: \(error)")
            return false
        }
    }
    
    private func advanceToNextQuestion() {
        // ... (この関数は変更なし)
        var currentIndex = UserDefaults.standard.integer(forKey: currentIndexKey)
        currentIndex += 1
        UserDefaults.standard.set(currentIndex, forKey: currentIndexKey)
        print("ℹ️ Advanced to next daily question. New index: \(currentIndex)")
    }
    
    /// ★★★ DataServiceのキャッシュ機能を使うように修正 ★★★
    private func findQuestion(withID id: String) async -> Question? {
        do {
            // 新しいキャッシュ対応の関数を呼び出す
            let allQuestions = try await DataService.shared.getAllQuestions()
            return allQuestions.first(where: { $0.id == id })
        } catch {
            return nil
        }
    }
    
    private func dateToString(_ date: Date) -> String {
        // ... (この関数は変更なし)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
*/