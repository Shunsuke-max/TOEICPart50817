import Foundation
import Combine
import SwiftData
import UserNotifications // ★★★ 追加 ★★★

@MainActor
class AppNotificationManager: ObservableObject {
    
    static let shared = AppNotificationManager()
    
    // 表示すべき実績を保持する。値が入ったらUIに変更を通知。
    @Published var achievementToDisplay: AchievementType?
    
    private init() {}
    
    /// 新しい実績が解除されていないかチェックし、あれば表示キューに追加する
    func checkForNewAchievements(context: ModelContext) {
        // すでに何か表示中の場合は、チェックしない（通知の渋滞を防ぐ）
        guard achievementToDisplay == nil else { return }
        
        if let newAchievements = AchievementManager.checkAndAwardAchievements(context: context) {
            // 複数の実績が同時に解除された場合、とりあえず最初のものを表示する
            achievementToDisplay = newAchievements.first
        }
    }
    
    // ★★★ 通知許可を要求するメソッド ★★★
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted.")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}
