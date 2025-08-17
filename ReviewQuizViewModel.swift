import Foundation
import Combine
import SwiftData

@MainActor
class ReviewQuizViewModel: ObservableObject {
    @Published var questions: [Question]
    @Published var reviewItems: [ReviewItem]
    
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var isAnswerSubmitted: Bool = false
    
    // どの問題にどう答えたかを記録する
    private var userAnswers: [String: Int] = [:] // questionID: answerIndex
    
    var currentQuestion: Question {
        questions[currentQuestionIndex]
    }
    
    var isQuizFinished: Bool {
        currentQuestionIndex >= questions.count
    }
    
    private var startTime: Date! // 学習開始時間
    private let reviewManager: ReviewManager // ReviewManagerのインスタンスを追加

    init(reviewItems: [ReviewItem], questions: [Question], modelContext: ModelContext) { // modelContextを追加
        self.reviewItems = reviewItems
        self.questions = questions.shuffled().map { $0.shuffled() } // 問題と選択肢をシャッフル
        self.startTime = Date() // 開始時間を記録
        self.reviewManager = ReviewManager() // ReviewManagerを初期化
    }

    func selectAnswer(index: Int) {
        if isAnswerSubmitted { return }
        
        selectedAnswerIndex = index
        isAnswerSubmitted = true
        userAnswers[currentQuestion.id] = index
    }
    
    func nextQuestion() {
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            selectedAnswerIndex = nil
            isAnswerSubmitted = false
        } else {
            // これが最後の問題なら、クイズを終了させる
            currentQuestionIndex += 1
        }
    }
    
    func finishReviewSession(context: ModelContext) async {
        var correctCount = 0
        
        for item in reviewItems {
            guard let question = questions.first(where: { $0.id == item.questionID }) else { continue }
            
            let userAnswerIndex = userAnswers[item.questionID]
            let wasCorrect = (userAnswerIndex == question.correctAnswerIndex)
            
            if wasCorrect {
                correctCount += 1
            }
            
            let quality = wasCorrect ? 4 : 1 // 4 for correct, 1 for incorrect
            await reviewManager.updateReviewItem(questionID: item.questionID, quality: quality, modelContext: context)
        }
        
        
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        StudyTimeManager.shared.add(time: elapsedTime)
        
        // レビューセッション完了日時を記録
        SettingsManager.shared.lastReviewSessionDate = Date()
        
        do {
            try context.save()
            print("✅ Review session finished and data saved.")
        } catch {
            print("❌ Failed to save context after review session: \(error)")
        }
    }
}
