import Foundation
import Combine
import SwiftData

/// 模試の複雑な状態（フェーズ、問題キュー、タイマー）を専門に管理するViewModel
@MainActor
class MockTestViewModel: ObservableObject {
    
    // MARK: - Enums and Properties
    
    enum Phase {
        case takingTest
        case scoring
        case finished
    }

    @Published var phase: Phase = .takingTest {
        didSet {
            if phase == .takingTest {
                startTimer()
            } else {
                timer?.cancel()
            }
        }
    }
    @Published var sessionRemainingTime: Int
    @Published var userAnswers: [String: Int] = [:]
    @Published var markedQuestions: Set<String> = []
    
    // Test Flow
    @Published private(set) var currentQuestionIndex: Int = 0
    var currentQuestion: Question {
        return originalQuestions[currentQuestionIndex]
    }
    
    // Result Data
    @Published var score: Int = 0
    @Published var highestScore: Int = 0 // Add this line
    let originalQuestions: [Question]
    
    private var timer: AnyCancellable?
    private let mockTestDuration = 900 // 15分
    private var startTime: Date! // 学習開始時間

    // MARK: - Initializer
    
    init?(session: MockTestSession, questions: [Question]) {
        print("MockTestViewModel init")
        // 問題リストが空の場合は初期化に失敗し、クラッシュを防ぐ
        guard !questions.isEmpty else {
            return nil
        }
        
        self.originalQuestions = questions.shuffled().map { $0.shuffled() }
        self.sessionRemainingTime = mockTestDuration
        self.startTime = Date() // 開始時間を記録
        
        startTimer()
    }
    
    deinit {
        print("MockTestViewModel deinit")
        timer?.cancel()
    }

    // MARK: - Public Methods
    
    /// 答えを選択する（自動で次へは進まない）
    func selectAnswer(answerIndex: Int) {
        print("selectAnswer called: \(answerIndex)")
        objectWillChange.send() // Explicitly notify SwiftUI of impending changes
        var tempUserAnswers = userAnswers
        tempUserAnswers[currentQuestion.id] = answerIndex
        userAnswers = tempUserAnswers // Assign a new dictionary to trigger update
    }

    /// 問題をマーク/マーク解除する
    func toggleMarkForReview(questionId: String) {
        if markedQuestions.contains(questionId) {
            markedQuestions.remove(questionId)
            print("Unmarked question: \(questionId)")
        } else {
            markedQuestions.insert(questionId)
            print("Marked question: \(questionId)")
        }
    }
    
    /// 次の問題へ進む
    func moveToNextQuestion() {
        print("moveToNextQuestion called")
        if currentQuestionIndex < originalQuestions.count - 1 {
            currentQuestionIndex += 1
        } else {
            // 全ての問題に解答したら、採点フェーズに移行
            phase = .scoring
            timer?.cancel()
        }
    }
    
    /// 前の問題へ戻る
    func moveToPreviousQuestion() {
        print("moveToPreviousQuestion called")
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    /// 指定されたインデックスの問題にジャンプする
    func jumpToQuestion(index: Int) {
        print("jumpToQuestion called: \(index)")
        if index >= 0 && index < originalQuestions.count {
            currentQuestionIndex = index
        }
    }
    
    /// 採点を実行し、結果画面へ遷移させる
    func finalizeAndScore(context: ModelContext) {
        print("finalizeAndScore called")
        var finalScore = 0
        for question in originalQuestions {
            if let userAnswerIndex = userAnswers[question.id], userAnswerIndex == question.correctAnswerIndex {
                finalScore += 1
            }
        }
        self.score = finalScore
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        StudyTimeManager.shared.add(time: elapsedTime)
        
        // QuizResultを保存
        let newResult = QuizResult(
            id: UUID(),
            setId: "mock_test", // 模試用のID
            score: finalScore,
            totalQuestions: originalQuestions.count,
            date: Date(),
            incorrectQuestionIDs: originalQuestions.filter { userAnswers[$0.id] != $0.correctAnswerIndex }.map { $0.id },
            duration: elapsedTime
        )
        context.insert(newResult)

        // 過去の模試結果から最高スコアを計算
        var descriptor = FetchDescriptor<QuizResult>(predicate: #Predicate { $0.setId == "mock_test" })
        descriptor.sortBy = [SortDescriptor(\.score, order: .reverse)]
        descriptor.fetchLimit = 1
        
        let pastMockResults = try? context.fetch(descriptor)
        self.highestScore = pastMockResults?.first?.score ?? 0 // Set highestScore
        
        _ = UserStatsManager.shared.addXP(originalQuestions.count * 2) // 模試はXP多め
        AchievementManager.logMockTestCompletion(context: context)
        QuizCompletionNotifier.shared.quizDidComplete.send()
        
        self.phase = .finished
        self.timer?.cancel()
        self.markedQuestions.removeAll()
    }

    func resetForRetry() {
        print("resetForRetry called")
        
        // Reset all state properties
        userAnswers.removeAll()
        markedQuestions.removeAll()
        currentQuestionIndex = 0
        score = 0
        sessionRemainingTime = mockTestDuration
        startTime = Date()
        
        // This will trigger the timer to restart via the `didSet` observer
        phase = .takingTest
    }

    // MARK: - Private Helper Methods
    
    private func startTimer() {
        print("startTimer called")
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, self.phase == .takingTest else { return }
            
            if self.sessionRemainingTime > 0 {
                self.sessionRemainingTime -= 1
                print("Timer: \(self.sessionRemainingTime)")
            } else {
                // 時間切れになったら、強制的に採点フェーズへ
                self.phase = .scoring
                self.timer?.cancel()
                print("Timer finished")
            }
        }
    }
}
