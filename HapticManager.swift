import UIKit

/// 触覚フィードバック（Haptics）を管理するクラス
class HapticManager {
    
    static let shared = HapticManager()
    private init() {}

    /// 成功を伝えるフィードバック（ポロン、という感じ）
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 失敗・エラーを伝えるフィードバック（ブッブー、という感じ）
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// 汎用的なインパクトフィードバックを再生する内部関数
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    // --- ここからが追加部分 ---

    /// 「コツン」という硬質なフィードバック (ボタン押下などに最適)
    static func rigidTap() {
        shared.playImpact(style: .rigid)
    }
    
    /// 「フワッ」という柔らかいフィードバック (リストの境界などに最適)
    static func softTap() {
        shared.playImpact(style: .soft)
    }
    
    /// 「ゴトッ」という重いフィードバック (カードのスワイプなどに最適)
    static func heavyImpact() {
        shared.playImpact(style: .heavy)
    }
    
    /// 「トントン」という中程度のフィードバック
    static func mediumImpact() {
        shared.playImpact(style: .medium)
    }
}
