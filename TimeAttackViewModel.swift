import Foundation
import Combine

@MainActor
class TimeAttackViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var currentEngineViewModel: QuizEngineViewModel?
    @Published var isQuizFinished: Bool = false
    @Published var timeAttackRemainingTime: Int
    @Published var incorrectCount: Int = 0
    @Published var score: Int = 0
    @Published var attemptedCount: Int = 0
    
    // MARK: - Properties
    private var timeAttackTimer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>() // 追加
    private let timeAttackDuration = 300 // 5分
    private let incorrectPenaltySeconds = 5 // 不正解時のペナルティ時間（秒）
    private var startTime: Date! // 学習開始時間
    
    private let questions: [Question]
    private var currentQuestionIndex: Int = 0
    let mistakeLimit: Int
    let totalQuestionsCount: Int // 追加
    let selectedCourseIDs: Set<String> // 追加
    
    // For Result View
    private(set) var originalQuestions: [Question]
    private(set) var incorrectQuestions: [Question] = []
    private(set) var answeredQuestions: [String: Int] = [:]
    private(set) var totalElapsedTime: TimeInterval = 0 // 追加

    // MARK: - Initializer
    init(questions: [Question], mistakeLimit: Int, selectedCourseIDs: Set<String>) {
        self.questions = questions.map { $0.shuffled() }
        self.originalQuestions = questions
        self.mistakeLimit = mistakeLimit
        self.selectedCourseIDs = selectedCourseIDs
        self.timeAttackRemainingTime = timeAttackDuration
        self.startTime = Date() // 開始時間を記録
        self.totalQuestionsCount = questions.count // 初期化
    }
    
    func startGame() {
        setupNextQuestion()
        startTimeAttackTimer()
    }
    
    func selectOption(at index: Int) {
        currentEngineViewModel?.selectOption(at: index)
    }
    
    deinit {
        timeAttackTimer?.cancel()
    }

    // MARK: - Private Helper Methods
    
    private func setupNextQuestion() {
        guard currentQuestionIndex < questions.count else {
            endQuiz(reason: "全問解答")
            return
        }
        
        let question = questions[currentQuestionIndex]
        self.currentEngineViewModel = QuizEngineViewModel(question: question)
        
        // QuizEngineViewModelのisCorrectプロパティを監視
        self.currentEngineViewModel?.$isCorrect
            .compactMap { $0 } // nilでない値のみを通過させる
            .sink { [weak self] isCorrect in
                self?.handleAnswer(isCorrect: isCorrect, for: question)
            }
            .store(in: &cancellables)
    }
    
    private func handleAnswer(isCorrect: Bool, for question: Question) {
        // 解答した問題の記録
        answeredQuestions[question.id] = currentEngineViewModel?.selectedAnswerIndex
        attemptedCount += 1
        
        if isCorrect {
            score += 1
        } else {
            incorrectCount += 1
            incorrectQuestions.append(question)
            
            // 不正解時にペナルティ時間を減算
            timeAttackRemainingTime = max(0, timeAttackRemainingTime - incorrectPenaltySeconds)
            
            // ミス許容回数に達したら終了
            if mistakeLimit != 0 && incorrectCount >= mistakeLimit {
                endQuiz(reason: "ミス許容回数超過")
                return
            }
        }
        
        // 少し遅れて次の問題へ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.currentQuestionIndex += 1
            self.setupNextQuestion()
        }
    }
    
    private func startTimeAttackTimer() {
        timeAttackTimer?.cancel()
        timeAttackTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            if self.timeAttackRemainingTime > 0 {
                self.timeAttackRemainingTime -= 1
            } else {
                self.endQuiz(reason: "時間切れ")
            }
        }
    }
    
    private func endQuiz(reason: String) {
        guard !isQuizFinished else { return }
        print("クイズ終了: \(reason)")
        timeAttackTimer?.cancel()
        isQuizFinished = true
        
        totalElapsedTime = Date().timeIntervalSince(startTime) // 経過時間を記録
        StudyTimeManager.shared.add(time: totalElapsedTime)
    }
    
    // 平均解答時間 (秒)
    var averageAnswerTime: Double {
        guard attemptedCount > 0 else { return 0 }
        return totalElapsedTime / Double(attemptedCount)
    }
    
    // 不正解問題のカテゴリ集計
    var incorrectCategoryCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for question in incorrectQuestions {
            counts[question.category ?? "不明なカテゴリ", default: 0] += 1
        }
        return counts
    }
}
