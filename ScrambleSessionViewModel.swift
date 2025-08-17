import SwiftUI

@MainActor
class ScrambleSessionViewModel: ObservableObject {
    @Published var questions: [SyntaxScrambleQuestion]
    @Published var currentQuestionIndex: Int = 0
    @Published var showResultView = false

    private(set) var sessionResults: [(question: SyntaxScrambleQuestion, isCorrect: Bool)] = []
    
    var progress: Float {
        // 完了した問題数に基づいてプログレスを計算
        Float(sessionResults.count) / Float(questions.count)
    }
    
    init(questions: [SyntaxScrambleQuestion]) {
        self.questions = questions
    }
    
    func recordResult(question: SyntaxScrambleQuestion, isCorrect: Bool) {
        // 結果を記録
        sessionResults.append((question, isCorrect))
        
        // 正解の場合のみ、進捗マネージャーに記録
        if isCorrect {
            ScrambleProgressManager.shared.markAsCompleted(id: question.id)
        }
    }
    
    func goToNextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else {
            // 全問終了
            showResultView = true
        }
    }
    
    func createResultData() -> ResultData {
        let correctAnswers = sessionResults.filter { $0.isCorrect }.count
        let totalQuestions = questions.count
        let score = correctAnswers
        // 以前の修正に合わせてResultReviewItemを使用
        let reviewableQuestions = sessionResults.map { ResultReviewItem(question: $0.question, userAnswer: nil, isCorrect: $0.isCorrect) }

        // 評価を決定 (ResultEvaluationの代わりにタプルを直接生成)
        let accuracy = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0
        let evaluation: (title: String, message: String, color: Color)
        if accuracy >= 0.8 {
            evaluation = ("素晴らしい！", "よくできました！", .blue)
        } else if accuracy >= 0.5 {
            evaluation = ("まずまずです", "この調子で頑張りましょう！", .orange)
        } else {
            evaluation = ("要復習", "間違えた問題をしっかり確認しましょう。", .red)
        }
        
        // 統計情報を作成 (ResultStatisticの代わりにタプルの配列を使用)
        let statistics: [(label: String, value: String)] = [
            (label: "正解率", value: "\(Int(accuracy * 100))%"),
            (label: "モード", value: "並び替え")
        ]
        
        // アクションボタンを定義
        let primaryAction = ResultAction(type: .backToHome, isPrimary: true)
        let secondaryActions = [ResultAction(type: .reviewMistakes, isPrimary: false)]
        
        return ResultData(
            score: score,
            totalQuestions: totalQuestions,
            evaluation: evaluation,
            statistics: statistics,
            reviewableQuestions: reviewableQuestions,
            primaryAction: primaryAction,
            secondaryActions: secondaryActions,
            mode: .scramble,
            difficulty: nil,
            selectedSkills: nil,
            selectedGenres: nil,
            mistakeTolerance: nil,
            timeLimit: nil,
            selectedCourseIDs: nil,
            mistakeLimit: nil
        )
    }
}