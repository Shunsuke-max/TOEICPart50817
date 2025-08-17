/*
import Foundation
import Combine

/// 「今日の一問」のロジックのみを管理するViewModel
@MainActor
class DailyQuizViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var engineViewModel: QuizEngineViewModel
    @Published var isQuizFinished: Bool = false
    
    let question: Question
    var isCorrect: Bool?
    private var startTime: Date // 学習開始時間
    private var cancellables = Set<AnyCancellable>() // 追加
    
    // MARK: - Initializer
    
    init(question: Question) {
            self.question = question
            self.isQuizFinished = false
            self.isCorrect = nil
            self.startTime = Date() // 開始時間を記録
            
            // QuizEngineViewModelを初期化
            self.engineViewModel = QuizEngineViewModel(question: question.shuffled())
            
            // engineViewModelのisCorrectプロパティを監視
            self.engineViewModel.$isCorrect
                .compactMap { $0 } // nilでない値のみを通過させる
                .sink { [weak self] isCorrect in
                    self?.handleAnswer(isCorrect: isCorrect)
                }
                .store(in: &cancellables)
        }
    
    // MARK: - Private Helper
    
    private func handleAnswer(isCorrect: Bool) {
        self.isCorrect = isCorrect
        self.isQuizFinished = true
        
        let elapsedTime = Date().timeIntervalSince(startTime) // 経過時間を計算
        StudyTimeManager.shared.add(time: elapsedTime) // 学習時間を追加
        
        // DailyQuizManagerに結果を記録する (元のQuizViewModelのロジックを流用)
        DailyQuizManager.shared.recordAttempt(wasCorrect: isCorrect)
        if isCorrect {
            // ミッションイベントを記録
            MissionManager.shared.logEvent(type: .completeDailyQuiz)
        }
    }
}
*/