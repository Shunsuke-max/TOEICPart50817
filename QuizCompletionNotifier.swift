import Foundation
import Combine

/// クイズ完了をアプリ全体に通知するためのクラス
final class QuizCompletionNotifier {
    
    // アプリ内で常に同じインスタンスにアクセスできるようにする
    static let shared = QuizCompletionNotifier()
    
    // Combineフレームワークを使った通知用のPublisher
    let quizDidComplete = PassthroughSubject<Void, Never>()
    
    // 外部からのインスタンス化を防ぐ
    private init() {}
}
