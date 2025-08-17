import SwiftUI
import FirebaseCore
import GoogleMobileAds
import UserNotifications
import SwiftData

@main
struct TOEICPart5QuizApp: App {
    @StateObject private var storeManager = StoreManager.shared

    init() {
        FirebaseApp.configure()
        MobileAds.shared.start(completionHandler: nil)
        // ★★★ Proユーザー向け通知の初期設定を呼び出す ★★★
        MockTestManager.shared.scheduleNewSetReminder()
        
        // BGMの再生はHomeViewで制御するため、ここでは呼び出さない
    }

    var body: some Scene {
            WindowGroup {
                ContentView()
                    .preferredColorScheme(.light)
                    // ★★★ 各Viewで使えるように環境オブジェクトとして渡す ★★★
                    .environmentObject(storeManager)
                    // ★★★ アプリ起動時に購入状態を更新 ★★★
                    .task {
                        await storeManager.updatePurchasedStatus()
                    }
            }
            .modelContainer(for: [QuizResult.self, BookmarkedQuestion.self, UnlockedAchievement.self, ReviewItem.self])
        }
    }
