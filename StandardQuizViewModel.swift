import Foundation
import Combine
import SwiftData

/// 通常クイズのセッション全体（問題リスト、スコア、進捗）を管理するViewModel
@MainActor
class StandardQuizViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentEngineViewModel: QuizEngineViewModel?
    @Published var isQuizFinished: Bool = false
    @Published var isBookmarked: Bool = false
    @Published var remainingTime: Int
    @Published var shouldShowCorrectAnimation: Bool // 新しく追加
    
    // MARK: - Properties
    
    private(set) var originalQuestions: [Question]
    private(set) var questions: [Question]
    private(set) var currentQuestionIndex: Int = 0
    private(set) var score: Int = 0
    private(set) var incorrectQuestions: [Question] = []
    private var startTime: Date!
    private var questionResults: [String: Bool] = [:] // 追加
    var userSelectedAnswers: [String: Int] = [:] // 新しく追加
    
    let timePerQuestion: Int
    private var timer: AnyCancellable?
    
    var progress: CGFloat {
        guard !questions.isEmpty else { return 0 }
        return isQuizFinished ? 1.0 : CGFloat(currentQuestionIndex) / CGFloat(questions.count)
    }
    var questionNumberText: String {
        let total = questions.count
        let number = min(currentQuestionIndex + 1, total)
        return "問題 \(number) / \(total)"
    }
    var nextButtonText: String {
        return currentQuestionIndex + 1 < questions.count ? "次の問題へ" : "結果を見る"
    }
    
    // For Result View
    let quizSet: QuizSet
    let course: Course?
    let allSetsInCourse: [QuizSet]?
    
    // 新しく追加するクイズ設定情報
    let difficulty: Int?
    let selectedSkills: [String]?
    let selectedGenres: [String]?
    let mistakeTolerance: Int?
    
    // private let reviewManager: ReviewManager // コメントアウト
    
    // MARK: - Initializer
    
    init(quizSet: QuizSet, course: Course?, allSetsInCourse: [QuizSet]?, timeLimit: Int, difficulty: Int?, selectedSkills: [String]?, selectedGenres: [String]?, mistakeTolerance: Int?) {
        self.quizSet = quizSet
        self.course = course
        self.allSetsInCourse = allSetsInCourse
        self.timePerQuestion = timeLimit
        self.remainingTime = timeLimit
        // self.reviewManager = ReviewManager() // コメントアウト
        self.difficulty = difficulty
        self.selectedSkills = selectedSkills
        self.selectedGenres = selectedGenres
        self.mistakeTolerance = mistakeTolerance
        self.startTime = Date()
        
        // 模試や実力診断テスト、達成度テストではアニメーションを表示しない
        let noAnimationSetIds: Set<String> = [
            "MOCK_TEST_WEEK_1", "MOCK_TEST_WEEK_2", "MOCK_TEST_WEEK_3", "MOCK_TEST_WEEK_4", "MOCK_TEST_WEEK_5",
            "DIAGNOSTIC_TEST"
        ]
        self.shouldShowCorrectAnimation = !noAnimationSetIds.contains(quizSet.setId) && !quizSet.setId.hasSuffix("_ACHIEVEMENT_TEST")
        
        let shuffled = quizSet.questions.shuffled()
        self.originalQuestions = shuffled
        self.questions = shuffled.map { $0.shuffled() }
        
        print("DEBUG: SQVM.init - Questions count after shuffling: \(self.questions.count)") // ここにログを追加
        
        // ここにチェックを追加
        if self.questions.isEmpty {
            print("⚠️ StandardQuizViewModel initialized with no questions. Setting isQuizFinished to true.")
            self.isQuizFinished = true
        } else {
            setupNextQuestion()
        }
    }

    deinit {
        timer?.cancel()
    }
    
    // MARK: - Public Methods
    
    func nextQuestion() {
        guard !isQuizFinished else { return }
        
        // ★★★ ここからが変更点 ★★★
        // 1. 現在の問題の解答を処理する
        processCurrentAnswer()
        
        // 2. タイマーを止める
        stopTimer()
        
        // 3. 次の問題へ進む
        currentQuestionIndex += 1
        if currentQuestionIndex < questions.count {
            setupNextQuestion()
        } else {
            // 4. 全ての問題が終わったら、最終スコアを計算してクイズを終了
            calculateFinalScoreAndIncorrectQuestions()
            isQuizFinished = true
        }
        // ★★★ ここまでが変更点 ★★★
    }
    
    func saveResult(context: ModelContext) async { // context引数を追加
        guard isQuizFinished else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime) // 実際の経過時間を計算
        
        let newResult = QuizResult(
            id: UUID(),
            setId: self.quizSet.setId,
            score: self.score,
            totalQuestions: self.questions.count,
            date: Date(),
            incorrectQuestionIDs: self.incorrectQuestions.map { $0.id },
            duration: elapsedTime
        )
        context.insert(newResult) // 引数のcontextを使用
        do {
            try context.save() // データを永続化
        } catch {
            print("❌ Failed to save QuizResult: \(error)")
        }
        print("✅ QuizResult saved for setId: \(self.quizSet.setId).")
        
        StudyTimeManager.shared.add(time: elapsedTime)
        
        // ReviewManagerの更新をここで行う
        /*
        for question in self.questions {
            if let isCorrect = questionResults[question.id] {
                if isCorrect {
                    await reviewManager.updateReviewItem(questionID: question.id, quality: 5, modelContext: context)
                } else {
                    await reviewManager.updateReviewItem(questionID: question.id, quality: 0, modelContext: context)
                }
            }
        }
        */
        
        ReviewRequestManager.incrementCompletionCount()
        
        AchievementManager.logAnyQuizCompletion(context: context)
        let accuracy = (Double(self.score) / Double(self.questions.count)) * 100
        AchievementManager.logQuizAccuracy(percentage: accuracy, context: context)
    }
    
    func updateBookmarkStatus(bookmarkedIDs: Set<String>) {
        guard let currentQuestion = currentEngineViewModel?.question else { return }
        self.isBookmarked = bookmarkedIDs.contains(currentQuestion.id)
    }
    
    func toggleBookmark(context: ModelContext) async { // context引数を追加
        guard let questionId = currentEngineViewModel?.question.id else { return }
        
        let descriptor = FetchDescriptor<BookmarkedQuestion>(predicate: #Predicate { $0.questionID == questionId })
        
        do {
            if let existingBookmark = try context.fetch(descriptor).first { // 引数のcontextを使用
                context.delete(existingBookmark) // 引数のcontextを使用
                try context.save() // データを永続化
            } else {
                let newBookmark = BookmarkedQuestion(questionID: questionId, dateBookmarked: .now)
                context.insert(newBookmark) // 引数のcontextを使用
                try context.save() // データを永続化
            }
            self.isBookmarked.toggle()
        } catch {
            print("❌ Failed to fetch or update bookmark: \(error)")
        }
    }
    
    func getIncorrectQuestions() -> [Question] {
        return incorrectQuestions
    }
    
    func restartQuiz() {
        self.score = 0
        self.incorrectQuestions.removeAll()
        self.currentQuestionIndex = 0
        self.isQuizFinished = false
        self.questions = self.originalQuestions.shuffled().map { $0.shuffled() }
        setupNextQuestion()
    }
    
    func submitCurrentAnswer() {
        currentEngineViewModel?.submitAnswer()
    }

    // ★★★ 新しく追加するメソッド ★★★
    /// ユーザーが選択肢を選択したときの処理をここに集約する
    func selectAnswer(at index: Int) {
        guard let viewModel = currentEngineViewModel, !viewModel.isAnswerLocked else { return }

        // 正解かどうかを判定
        let isCorrect = (index == viewModel.question.correctAnswerIndex)

        // 正解・不正解に応じて即座に効果音を再生
        if isCorrect {
            SoundManager.shared.playSound(named: "CorrectAnswer.mp3")
            HapticManager.shared.playSuccess()
        } else {
            SoundManager.shared.playSound(named: "WrongAnswer.mp3")
            HapticManager.shared.playError()
        }

        // UIの状態を更新し、解答をロックする
        viewModel.selectedAnswerIndex = index
        viewModel.isCorrect = isCorrect
        viewModel.isAnswerSubmitted = true
        viewModel.isAnswerLocked = true
    }
    
    // MARK: - Private Helper Methods""
    
    /// 現在の問題の解答が正解か不正解かを記録する
    private func processCurrentAnswer() {
        guard let viewModel = currentEngineViewModel else { return }
        
        // isCorrectがnil（未解答）の場合はfalseとして扱う
        let isCorrect = viewModel.isCorrect ?? false
        questionResults[viewModel.question.id] = isCorrect
        userSelectedAnswers[viewModel.question.id] = viewModel.selectedAnswerIndex // ユーザーの選択を保存
    }
    
    private func setupNextQuestion() {
        guard !questions.isEmpty else {
            print("⚠️ setupNextQuestion called with empty questions array. Skipping.")
            return
        }
        let question = questions[currentQuestionIndex]
        self.currentEngineViewModel = QuizEngineViewModel(question: question) // onAnsweredを削除
        startTimer()
    }
    
    private func startTimer() {
        guard timePerQuestion != SettingsManager.shared.timerOffValue else { return }
        
        remainingTime = timePerQuestion
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.stopTimer()
                self.currentEngineViewModel?.timeUp()
            }
        }
    }
    
    private func stopTimer() {
        timer?.cancel()
    }
    
    private func calculateFinalScoreAndIncorrectQuestions() {
        score = 0
        incorrectQuestions.removeAll()
        
        for question in questions { // originalQuestionsではなくquestionsをループ
            if let isCorrect = questionResults[question.id] {
                if isCorrect {
                    score += 1
                } else {
                    incorrectQuestions.append(question)
                }
            }
        }
    }
}
