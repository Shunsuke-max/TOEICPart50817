import Foundation
import SwiftUI
import Combine // 追加

@MainActor
class SurvivalViewModel: ObservableObject {
    
    enum SurvivalType {
        case normal
        case onimon // 鬼問モード
    }
    
    enum GamePhase {
        case playing
        case waitingForRevive
        case readyToResume
        case gameOver
    }
    
    @Published var phase: GamePhase = .playing
    @Published var currentEngineViewModel: QuizEngineViewModel?
    @Published var score: Int = 0
    @Published var highScore: Int = 0
    @Published var finalIncorrectQuestion: Question?
    @Published var correctQuestions: [Question] = [] // ★ 正解した問題
    @Published var incorrectQuestions: [Question] = [] // ★ 不正解だった問題
    @Published var isLoading: Bool = true
    @Published var timeRemaining: Double = 0 // 残り時間
    @Published var errorMessage: String? // 追加
    @Published var showingErrorAlert: Bool = false // 追加
    @Published var showGameOverEffect: Bool = false // 追加
    private var cancellables = Set<AnyCancellable>() // 追加
    let timeLimit: Double = 30 // 1問あたりの制限時間
    private var timer: Timer?
    private let modeType: SurvivalType
    private var hasUsedReviveThisSession: Bool = false
    private var questionPool: [Question] = []
    private var startTime: Date! // 学習開始時間
    
    init(type: SurvivalType) {
            self.modeType = type
            self.highScore = UserStatsManager.shared.getSurvivalHighScore(for: type) // ハイスコアは共通
        }
    
    func prepareAndStartGame() async {
            isLoading = true
            errorMessage = nil // エラーメッセージをリセット
            showingErrorAlert = false // アラート表示フラグをリセット
            
            do {
                // ★★★ モードに応じて読み込む問題を変える ★★★
                switch modeType {
                case .normal:
                    self.questionPool = (try await DataService.shared.getAllQuestions()).shuffled() ?? []
                case .onimon:
                    self.questionPool = try await DataService.shared.loadOnimonQuestions().shuffled()
                }
                
                guard !self.questionPool.isEmpty else {
                    errorMessage = "問題の読み込みに失敗しました。利用可能な問題がありません。"
                    showingErrorAlert = true
                    isLoading = false
                    return
                }

            } catch {
                errorMessage = "問題の読み込みに失敗しました。\n詳細: \(error.localizedDescription)"
                showingErrorAlert = true
                isLoading = false
                return
            }
            
            self.score = 0
            self.phase = .playing
            self.hasUsedReviveThisSession = false
            self.startTime = Date() // 開始時間を記録
            setupNextEngineViewModel()
            isLoading = false
            startTimer()
        }

    private func startTimer() {
        timer?.invalidate()
        timeRemaining = timeLimit
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 {
                self.timer?.invalidate()
                self.handleAnswer(isCorrect: false) // 時間切れは不正解扱い
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        timeRemaining = timeLimit
    }

    private func handleAnswer(isCorrect: Bool) {
        stopTimer()
        
        guard let question = currentEngineViewModel?.question else { return }

        if isCorrect {
            score += 1
            correctQuestions.append(question)
            SoundManager.shared.playSound(named: "correct.wav")
            HapticManager.softTap()
        } else {
            incorrectQuestions.append(question)
            SoundManager.shared.playSound(named: "incorrect.wav")
            HapticManager.shared.playError()
            self.finalIncorrectQuestion = self.currentEngineViewModel?.question

            if !hasUsedReviveThisSession {
                phase = .waitingForRevive
            } else {
                forceEndGame()
            }
        }
    }
    
    // ✅ 解決策1: 状態遷移の責務を分離
    /// 広告視聴成功後、準備完了状態へ移行する
    func grantRevive() {
        guard phase == .waitingForRevive else { return }
        hasUsedReviveThisSession = true
        phase = .readyToResume
    }
    
    func selectOption(at index: Int) {
        currentEngineViewModel?.selectOption(at: index)
    }
    
    /// ユーザーが挑戦を再開する
    func resumeChallenge() {
        guard phase == .readyToResume else { return }
        phase = .playing
        moveToNextQuestion()
    }
    
    /// 次の問題へ進む
    func moveToNextQuestion() {
        guard phase == .playing else { return }
        
        // ✅ 解決策3: 予期しない動作の原因となる遅延処理を削除
        setupNextEngineViewModel()
    }
    
    func forceEndGame() {
        stopTimer()
        phase = .gameOver
        UserStatsManager.shared.updateSurvivalHighScore(newScore: score, for: modeType)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        StudyTimeManager.shared.add(time: elapsedTime)
        showGameOverEffect = true // ゲームオーバーエフェクトをトリガー
    }
    
    private func setupNextEngineViewModel() {
        if let nextQuestion = questionPool.popLast() {
            self.currentEngineViewModel = QuizEngineViewModel(question: nextQuestion)
            
            // QuizEngineViewModelのisCorrectプロパティを監視
            self.currentEngineViewModel?.$isCorrect
                .compactMap { $0 } // nilでない値のみを通過させる
                .sink { [weak self] isCorrect in
                    self?.handleAnswer(isCorrect: isCorrect)
                }
                .store(in: &cancellables)
            
            resetTimer()
        } else {
            forceEndGame()
        }
    }
}

