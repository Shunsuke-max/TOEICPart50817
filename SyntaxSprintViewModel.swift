import Foundation
import Combine
import SwiftData

@MainActor
class SyntaxSprintViewModel: ObservableObject {
    
    // MARK: - Game State Properties (Published to UI)
    @Published var remainingTime: Double = 90.0 // Double for smooth animation
    @Published var score: Int = 0 // Int as per user request
    @Published var comboCount: Int = 0
    @Published var maxCombo: Int = 0
    @Published var isGameOver: Bool = false
    @Published var currentQuestion: SyntaxScrambleQuestion? // Changed to var
    @Published var highScore: Int = 0 // This remains Int as it's likely for display/record keeping
    @Published var isNewHighScore: Bool = false
    @Published var reviewedQuestions: [ReviewedSyntaxSprintQuestion] = [] // Added this line
    @Published var showHint: Bool = false // 追加
    @Published var hintText: String = "" // 追加
    @Published var showJapaneseTranslation: Bool = false // 追加
    @Published var showResultAndExplanation: Bool = false // 追加
    @Published var lastQuestionCorrectOrder: String = "" // 追加
    @Published var lastQuestionExplanation: String = "" // 追加
    
    // ゲーム開始前の準備状態
    @Published var isLoading: Bool = true
    
    // MARK: - Game Logic Properties
    private var timer: AnyCancellable?
    static let initialTime: Double = 60.0 // Double for smooth animation
    let timeBonusPerCorrect: Int = 4
    let timePenaltyPerIncorrect: Int = 2
    private var startTime: Date! // 学習開始時間
    
    // 難易度別の問題プール
    private var questionsByLevel: [Int: [SyntaxScrambleQuestion]] = [:]
    private var shuffledLv1: [SyntaxScrambleQuestion] = []
    private var shuffledLv2: [SyntaxScrambleQuestion] = []
    private var shuffledLv3: [SyntaxScrambleQuestion] = []

    private let selectedDifficulty: Int
    private let selectedSkills: [String]
    private let selectedGenres: [String]

    private var reviewManager: ReviewManager = ReviewManager()
    private var modelContext: ModelContext! // Implicitly Unwrapped Optionalに変更
    
    init(difficulty: Int, skills: [String], genres: [String]) { // modelContextをinitから削除
        self.selectedDifficulty = difficulty
        self.selectedSkills = skills
        self.selectedGenres = genres
    }
    
    // modelContextを設定するメソッドを追加
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Game Lifecycle
    
    /// ゲームの準備
    func prepareGame() async {
        print("DEBUG: prepareGame() called.")
        isLoading = true
        await loadAndFilterQuestions()
        resetGame()
        isLoading = false
    }
    
    /// ゲームを開始する（カウントダウン後などに呼ばれる）
    func startGame() {
        print("DEBUG: startGame() called.")
        currentQuestion = fetchNextQuestion()
        if currentQuestion == nil {
            print("DEBUG: currentQuestion is nil after fetchNextQuestion(). Ending game.")
            endGame()
            return
        }
        print("DEBUG: First question set: \(currentQuestion!.id)")
        self.startTime = Date() // 開始時間を記録
        startTimer()
    }
    
    /// 解答を提出し、ゲームを進行させる
    func submitAnswer(isCorrect: Bool, userAnswer: [Chunk]) async {
        guard let currentQuestion = currentQuestion else { 
            print("DEBUG: submitAnswer called but currentQuestion is nil.")
            return 
        }

        // Record the question for review
        let reviewedQuestion = ReviewedSyntaxSprintQuestion(
            question: currentQuestion,
            userAnswer: userAnswer,
            isCorrect: isCorrect
        )
        reviewedQuestions.append(reviewedQuestion)

        // ReviewManagerで復習アイテムを更新
        await reviewManager.updateReviewItem(questionID: currentQuestion.id, quality: isCorrect ? 5 : 0, modelContext: modelContext)

        if isCorrect {
            score += 1 // score is Int, so add Int
            comboCount += 1
            maxCombo = max(maxCombo, comboCount)
            
            let bonusTime: Double
            if comboCount >= 30 {
                bonusTime = 2.0 // 30コンボ以上: +6秒 (基本+4秒 + コンボボーナス+2秒)
            } else if comboCount >= 10 {
                bonusTime = 1.0 // 10～29コンボ: +5秒 (基本+4秒 + コンボボーナス+1秒)
            } else {
                bonusTime = 0.0 // 1～9コンボ: +4秒 (基本タイム)
            }
            remainingTime += Double(timeBonusPerCorrect) + bonusTime // remainingTime is Double
            
            HapticManager.shared.playSuccess()
            SoundManager.shared.playSound(named: "correct.wav")

            // 正解の場合、解説を表示
            showResultAndExplanation = true
            lastQuestionCorrectOrder = currentQuestion.chunks.map { $0.text }.joined(separator: " ")
            lastQuestionExplanation = currentQuestion.explanation
            timer?.cancel() // タイマーを停止
            
        } else {
            comboCount = 0
            remainingTime -= Double(timePenaltyPerIncorrect) // remainingTime is Double
            
            if remainingTime < 0 { remainingTime = 0 }
            
            HapticManager.shared.playError()
            SoundManager.shared.playSound(named: "incorrect.wav")

            // 不正解の場合、すぐに次の問題へ
            if let nextQuestion = fetchNextQuestion() {
                print("DEBUG: Next question fetched: \(nextQuestion.id)")
                self.currentQuestion = nextQuestion // Assign to var
            } else {
                print("DEBUG: No more questions. Ending game.")
                endGame()
            }
        }
    }
    
    /// ユーザーの解答が正しいか判定する
    func isAnswerCorrect(userAnswer: [Chunk]) -> Bool {
        guard let currentQuestion = currentQuestion else { return false }
        let correctOrder = currentQuestion.chunks.map { $0.text }
        let providedOrder = userAnswer.map { $0.text }
        return correctOrder == providedOrder
    }

    func passQuestion() async {
        guard let currentQuestion = currentQuestion else { return }
        showResultAndExplanation = true
        lastQuestionCorrectOrder = currentQuestion.chunks.map { $0.text }.joined(separator: " ")
        lastQuestionExplanation = currentQuestion.explanation
        remainingTime -= 5.0 // パスした場合も時間ペナルティ
        if remainingTime < 0 { remainingTime = 0 }
        timer?.cancel() // タイマーを停止
        
        // パスした場合も不正解として記録
        await reviewManager.updateReviewItem(questionID: currentQuestion.id, quality: 0, modelContext: modelContext)
    }

    func dismissResultAndExplanation() {
        showResultAndExplanation = false
        lastQuestionCorrectOrder = ""
        lastQuestionExplanation = ""
        if let nextQuestion = fetchNextQuestion() {
            currentQuestion = nextQuestion
            startTimer() // タイマーを再開
        } else {
            endGame()
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// 問題データを読み込み、選択されたスキルとジャンルでフィルタリングする
    private func loadAndFilterQuestions() async {
        // すでに読み込み済みの場合は何もしない
        guard questionsByLevel.isEmpty else { 
            print("DEBUG: Questions already loaded. Skipping reload.")
            return 
        }
        
        do {
            print("DEBUG: Attempting to load syntax_scramble_vol1.json locally...")
            let quizSet = try DataService.shared.loadLocalSyntaxScrambleSet(from: "syntax_scramble_vol1.json")
            print("DEBUG: Successfully loaded syntax_scramble_vol1.json. Total questions: \(quizSet.syntaxScrambleQuestions.count)")
            
            var filteredQuestions: [SyntaxScrambleQuestion] = []

            print("DEBUG: Selected Difficulty: \(selectedDifficulty)")
            print("DEBUG: Selected Skills: \(selectedSkills)")
            print("DEBUG: Selected Genres: \(selectedGenres)")
            
            for question in quizSet.syntaxScrambleQuestions {
                let matchesDifficulty = (question.difficultyLevel <= self.selectedDifficulty)
                let matchesSkill = selectedSkills.isEmpty || selectedSkills.contains(question.skill)
                let matchesGenre = selectedGenres.isEmpty || selectedGenres.contains(question.genre)
                
                if matchesDifficulty && matchesSkill && matchesGenre {
                    filteredQuestions.append(question)
                } else {
                    print("DEBUG: Skipping question \(question.id) - Difficulty: \(matchesDifficulty), Skill: \(matchesSkill), Genre: \(matchesGenre)")
                }
            }

            print("DEBUG: Questions after filtering: \(filteredQuestions.count)")
            
            // 難易度別に分類
            for question in filteredQuestions {
                questionsByLevel[question.difficultyLevel, default: []].append(question)
            }
            
            // 各難易度レベルの問題数をログ出力
            for (level, questions) in questionsByLevel {
                print("DEBUG: Questions available for Level \(level): \(questions.count)")
            }
            
        } catch {
            print("❌ Syntax Scrambleのデータ読み込みに失敗: \(error)")
        }
    }
    
    /// ゲームの状態を初期化する
    private func resetGame() {
        score = 0 // score is Int
        comboCount = 0
        maxCombo = 0
        remainingTime = SyntaxSprintViewModel.initialTime
        isGameOver = false
        
        // 選択された難易度に基づいて初期の問題プールを構築
        switch selectedDifficulty {
        case 1: 
            self.shuffledLv1 = questionsByLevel[1]?.shuffled() ?? []
            print("DEBUG: Shuffled Lv1 questions count: \(self.shuffledLv1.count)")
            print("DEBUG: shuffledLv1 after resetGame: \(self.shuffledLv1.count)")
        case 2: 
            self.shuffledLv2 = questionsByLevel[2]?.shuffled() ?? []
            print("DEBUG: Shuffled Lv2 questions count: \(self.shuffledLv2.count)")
        case 3: 
            self.shuffledLv3 = questionsByLevel[3]?.shuffled() ?? []
            print("DEBUG: Shuffled Lv3 questions count: \(self.shuffledLv3.count)")
        default: 
            print("DEBUG: No questions shuffled for selected difficulty: \(selectedDifficulty)")
            break
        }
    }
    
    /// 次の問題を、現在のスコアに応じた難易度プールから取得する
    private func fetchNextQuestion() -> SyntaxScrambleQuestion? {
        print("DEBUG: fetchNextQuestion() called for difficulty: \(selectedDifficulty)")
        var question: SyntaxScrambleQuestion?
        switch selectedDifficulty {
        case 1: 
            print("DEBUG: shuffledLv1 count before popLast: \(shuffledLv1.count)")
            question = shuffledLv1.popLast()
            print("DEBUG: Remaining Lv1 questions: \(shuffledLv1.count)")
        case 2: 
            print("DEBUG: shuffledLv2 count before popLast: \(shuffledLv2.count)")
            question = shuffledLv2.popLast()
            print("DEBUG: Remaining Lv2 questions: \(shuffledLv2.count)")
        case 3: 
            print("DEBUG: shuffledLv3 count before popLast: \(shuffledLv3.count)")
            question = shuffledLv3.popLast()
            print("DEBUG: Remaining Lv3 questions: \(shuffledLv3.count)")
        default: 
            question = nil
            print("DEBUG: No question found for selected difficulty: \(selectedDifficulty)")
        }
        if question == nil {
            print("DEBUG: fetchNextQuestion() returning nil.")
        }
        return question
    }
    
    /// 1秒ごとに時間を減らすタイマーを開始する
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isGameOver else { return }
                
                if self.remainingTime > 0 {
                    self.remainingTime -= 0.01 // remainingTime is Double
                } else {
                    self.endGame()
                }
            }
    }
    
    /// ゲームを終了する
    func endGame() {
        isGameOver = true
        timer?.cancel()
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        StudyTimeManager.shared.add(time: elapsedTime)
        
        // ハイスコアの更新処理
        self.isNewHighScore = UserStatsManager.shared.updateSyntaxSprint(newScore: self.score, newMaxCombo: self.maxCombo) // score is Int, no cast needed
        self.highScore = Int(UserStatsManager.shared.getSyntaxSprintRecord().highScore) // Cast to Int for highScore
        
        // プレイ日時の記録
        GameModeManager.shared.recordSyntaxSprintPlay()
    }

    // MARK: - Hint Logic
    func applyHint(type: HintType) {
        comboCount = 0 // ヒント使用でコンボリセット
        remainingTime -= 5.0 // ヒント使用で時間ペナルティ

        switch type {
        case .firstChunk:
            if let firstChunk = currentQuestion?.chunks.first {
                hintText = "最初のチャンク: \(firstChunk.text)"
                showHint = true
            }
        case .japaneseTranslation:
            if let translation = currentQuestion?.explanation { // explanationを日本語訳として利用
                hintText = "日本語訳: \(translation)"
                showJapaneseTranslation = true
            }
        }
        // ヒント表示後、一定時間で非表示にする
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showHint = false
            self?.showJapaneseTranslation = false
            self?.hintText = ""
        }
    }
}

enum HintType {
    case firstChunk
    case japaneseTranslation
}
