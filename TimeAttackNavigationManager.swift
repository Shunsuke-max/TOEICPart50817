import Foundation
import Combine

/// タイムアタックの画面遷移（Navigation）の状態を管理するためのクラス
@MainActor
class TimeAttackNavigationManager: ObservableObject {
    // isLinkActiveを@Publishedにすることで、この値の変更をViewが監視できるようになる
    @Published var isLinkActive = false
}
