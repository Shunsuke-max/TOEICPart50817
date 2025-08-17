import Foundation
import UserNotifications

// 挑戦中の模試セッション情報を保存するための構造体
struct MockTestSession: Codable {
    let testSetId: String
    let questionIDs: [String] // このセッションでの問題順
    let startTime: Date
    var userAnswers: [String: Int] = [:] // 問題ID: 解答インデックス
    var timeSpent: TimeInterval = 0 // 中断時の経過時間
}

class MockTestManager {
    static let shared = MockTestManager()
    
    // UserDefaults用のキー
    private let lastCompletionDateKey = "mockTestLastCompletionDateKey"
    private let currentSessionKey = "mockTestCurrentSessionKey"

    private init() {}
    
    // MARK: - Public State Getters
    
    enum Availability {
        case available(testSetId: String)      // 受験可能
        case inProgress(session: MockTestSession) // 挑戦中
        case onCooldown(remaining: TimeInterval) // クールダウン中
        case proUserOnly                    // Pro限定機能で、週1回を超えた場合
    }

    /// 現在のユーザーの受験資格を返す
    func getAvailabilityState(for setId: String) -> Availability {
        // 第1回模試はPro会員でなくても何回でも挑戦可能
        if setId == "MOCK_TEST_WEEK_1" {
            return .available(testSetId: setId)
        }

        // 挑戦中のセッションがあれば最優先で返す（ただし、MOCK_TEST_WEEK_1以外の場合）
        if let session = getCurrentSession() {
            // If there's an in-progress session for a *different* test,
            // then the current test (setId) is not available.
            // If the in-progress session is for MOCK_TEST_WEEK_1,
            // it would have been caught by the first if statement.
            return .inProgress(session: session)
        }
        
        let isPremium = SettingsManager.shared.isPremiumUser
        
        // Proユーザーはクールダウンなし
        if isPremium {
            return .available(testSetId: setId)
        }
        
        // 無料ユーザーのクールダウンチェック
        if let lastCompletion = UserDefaults.standard.object(forKey: lastCompletionDateKey) as? Date {
            let cooldownEndTime = lastCompletion.addingTimeInterval(7 * 24 * 60 * 60) // 7日間
            let remainingTime = cooldownEndTime.timeIntervalSinceNow
            
            if remainingTime > 0 {
                return .onCooldown(remaining: remainingTime)
            }
        }
        
        // クールダウンが終わっているか、まだ一度もやっていない場合
        return .available(testSetId: setId)
    }

    // MARK: - Session Management

    /// 模試を開始する
    func startTest(questions: [Question], setId: String) -> MockTestSession {
        let session = MockTestSession(
            testSetId: setId,
            questionIDs: questions.map { $0.id },
            startTime: Date()
        )
        saveSession(session)
        return session
    }
    
    /// 模試を完了する
    func completeTest() {
            UserDefaults.standard.set(Date(), forKey: lastCompletionDateKey)
            clearCurrentSession()
            
            // ★★★ 無料ユーザーの場合のみ、クールダウン通知を予約 ★★★
            if !SettingsManager.shared.isPremiumUser {
                scheduleCooldownReminder()
            }
        }
    
    /// 現在のセッションを保存する（途中経過の保存用）
    func saveSession(_ session: MockTestSession) {
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: currentSessionKey)
        }
    }
    
    func getCurrentSession() -> MockTestSession? {
        guard let data = UserDefaults.standard.data(forKey: currentSessionKey) else { return nil }
        return try? JSONDecoder().decode(MockTestSession.self, from: data)
    }
    
    func clearCurrentSession() {
        UserDefaults.standard.removeObject(forKey: currentSessionKey)
    }
    
    func scheduleCooldownReminder() {
            let center = UNUserNotificationCenter.current()
            let notificationId = "mockTestCooldownNotification"
            
            // 既存の通知はキャンセル
            center.removePendingNotificationRequests(withIdentifiers: [notificationId])
            
            // クールダウン終了時刻を取得
            guard let lastCompletion = UserDefaults.standard.object(forKey: lastCompletionDateKey) as? Date else { return }
            let cooldownEndTime = lastCompletion.addingTimeInterval(7 * 24 * 60 * 60) // 7日後
            
            // 通知はその1時間前
            let notificationTime = cooldownEndTime.addingTimeInterval(-1 * 60 * 60)
            
            // 通知時刻が過去の場合は予約しない
            guard notificationTime > Date() else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "模試に再挑戦できます！"
            content.body = "Part5模試のクールダウンが終了しました。実力を試してみましょう！"
            content.sound = .default
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("❌ Cooldown notification error: \(error.localizedDescription)")
                } else {
                    print("✅ Cooldown notification scheduled.")
                }
            }
        }
        
        /// (Proユーザー向け) 新しい模試セットの公開を知らせる週次通知を予約する
        func scheduleNewSetReminder() {
            let center = UNUserNotificationCenter.current()
            let notificationId = "newMockTestSetNotification"

            // 既存の通知はキャンセル
            center.removePendingNotificationRequests(withIdentifiers: [notificationId])

            // Proユーザー、かつ設定がONの場合のみ予約する
            guard SettingsManager.shared.isPremiumUser,
                  SettingsManager.shared.isNewMockTestNotificationEnabled else {
                print("ℹ️ New mock test reminder is disabled.")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "新しい模試が公開されました！"
            content.body = "今週のPart5模試に挑戦して、実力を維持・向上させましょう！"
            content.sound = .default

            // 毎週月曜の午前9時など、定期的な日時を設定
            var dateComponents = DateComponents()
            dateComponents.weekday = 2 // 1が日曜、2が月曜
            dateComponents.hour = 9
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("❌ New set notification error: \(error.localizedDescription)")
                } else {
                    print("✅ Weekly new set notification scheduled.")
                }
            }
        }
}
