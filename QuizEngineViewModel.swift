import Foundation
import Combine

/// 1問分のクイズの状態とロジックのみを管理するViewModel
@MainActor
class QuizEngineViewModel: ObservableObject {
    
    // MARK: - Properties
    
    let question: Question
    
    @Published var selectedAnswerIndex: Int?
    @Published var isAnswerSubmitted: Bool
    @Published var isCorrect: Bool?
    @Published var isAnswerLocked: Bool // 追加
    
    init(question: Question) { // onAnsweredを削除
        self.question = question
        self.selectedAnswerIndex = nil
        self.isAnswerSubmitted = false
        self.isCorrect = nil
        self.isAnswerLocked = false // 初期化
    }
    
    // MARK: - Public Methods
    
    /// ユーザーが選択肢を選んだ時の処理
    func selectOption(at index: Int) {
        guard !isAnswerLocked else { return } // ロックされていたら何もしない
        
        self.selectedAnswerIndex = index
        self.isCorrect = (index == question.correctAnswerIndex)
        self.isAnswerLocked = true // 解答をロック
        
        // 効果音
        if isCorrect == true {
            SoundManager.shared.playSound(named: "CorrectAnswer.mp3")
        } else {
            SoundManager.shared.playSound(named: "WrongAnswer.mp3")
        }
        
        submitAnswer()
    }
    
    /// 時間切れになった時の処理
    func timeUp() {
        guard !isAnswerLocked else { return }
        
        // 状態を更新（未選択のまま解答済みにする）
        self.selectedAnswerIndex = nil
        self.isCorrect = false
        
        submitAnswer() // submitAnswerを呼び出す
    }

    /// 解答を確定する（次へ進むボタンが押された時など）
    func submitAnswer() {
        guard !isAnswerLocked else { return }
        self.isAnswerSubmitted = true
        self.isAnswerLocked = true // 解答をロック
        print("DEBUG: QEV.submitAnswer - Answer submitted for Question ID: \(question.id)")

        // 効果音と触覚フィードバック
        if let isCorrect = self.isCorrect {
            if isCorrect {
                // SoundManager.shared.playSound(named: "CorrectAnswer.mp3") // selectAnswerで再生済のため不要
                HapticManager.shared.playSuccess()
            } else {
                // SoundManager.shared.playSound(named: "WrongAnswer.mp3") // selectAnswerで再生済のため不要
                HapticManager.shared.playError()
            }
        } else { // 未選択で時間切れなどの場合
            SoundManager.shared.playSound(named: "WrongAnswer.mp3")
            HapticManager.shared.playError()
        }
    }
}
