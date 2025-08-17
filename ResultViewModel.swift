import SwiftUI
import Foundation

@MainActor
class ResultViewModel: ObservableObject {
    
    @Published var resultData: ResultData?

    func generateResult(
            score: Int,
            totalQuestions: Int,
            incorrectQuestions: [Question], // 間違えた問題のリスト
            allQuestionsInQuiz: [Question], // 出題されたすべての問題のリスト
            mode: ResultData.Mode = .standard,
            statistics: [(label: String, value: String)] = [],
            nextQuizSet: QuizSet? = nil,
            difficulty: Int? = nil,
            selectedSkills: [String]? = nil,
            selectedGenres: [String]? = nil,
            mistakeTolerance: Int? = nil,
            timeLimit: Int? = nil,
            selectedCourseIDs: Set<String>? = nil,
            mistakeLimit: Int? = nil,
            userSelectedAnswers: [String: Int] // 新しく追加
        ) {
            let accuracy = totalQuestions > 0 ? Double(score) / Double(totalQuestions) : 0
            let evaluation = determineEvaluation(for: accuracy)
            
            var primaryAction: ResultAction
            var secondaryActions: [ResultAction] = []

            // modeに応じてボタンの構成を変える
            switch mode {
            case .achievementTest:
                primaryAction = ResultAction(type: .backToCourse, isPrimary: true)
                secondaryActions.append(ResultAction(type: .tryAgain, isPrimary: false))
                
            case .vocabularyLesson:
                primaryAction = ResultAction(type: .tryAgain, isPrimary: true)
                secondaryActions.append(ResultAction(type: .backToCourse, isPrimary: false))

            case .standard, .timeAttack, .survival, .mockTest, .scramble:
                if accuracy >= 0.9 && nextQuizSet != nil {
                    primaryAction = ResultAction(type: .nextSet, isPrimary: true)
                    secondaryActions.append(ResultAction(type: .tryAgain, isPrimary: false))
                    secondaryActions.append(ResultAction(type: .backToHome, isPrimary: false))
                } else if accuracy >= 0.6 {
                    primaryAction = ResultAction(type: .tryAgain, isPrimary: true)
                    if nextQuizSet != nil {
                        secondaryActions.append(ResultAction(type: .nextSet, isPrimary: false))
                    }
                    secondaryActions.append(ResultAction(type: .backToHome, isPrimary: false))
                } else {
                    primaryAction = ResultAction(type: .tryAgain, isPrimary: true)
                    if nextQuizSet != nil {
                        secondaryActions.append(ResultAction(type: .nextSet, isPrimary: false))
                    }
                    secondaryActions.append(ResultAction(type: .backToHome, isPrimary: false))
                }
            }
            
            if !incorrectQuestions.isEmpty {
                secondaryActions.insert(ResultAction(type: .reviewMistakes, isPrimary: false), at: 0)
            }

            // 正解・不正解を含むレビュー用のリストを作成
            let incorrectQuestionIDs = Set(incorrectQuestions.map { $0.id })
            let reviewableItems = allQuestionsInQuiz.map { question -> ResultReviewItem in
                let isCorrect = !incorrectQuestionIDs.contains(question.id)
                let userAnswer = userSelectedAnswers[question.id] // ユーザーの選択した解答を取得
                return ResultReviewItem(question: question, userAnswer: userAnswer, isCorrect: isCorrect)
            }

            self.resultData = ResultData(
                score: score,
                totalQuestions: totalQuestions,
                evaluation: evaluation,
                statistics: statistics,
                reviewableQuestions: reviewableItems, // 新しいリストを使用
                primaryAction: primaryAction,
                secondaryActions: secondaryActions,
                mode: mode,
                difficulty: difficulty,
                selectedSkills: selectedSkills,
                selectedGenres: selectedGenres,
                mistakeTolerance: mistakeTolerance,
                timeLimit: timeLimit,
                selectedCourseIDs: selectedCourseIDs,
                mistakeLimit: mistakeLimit
            )
    }
    
    // ★★★ QuizResultからResultDataを生成するヘルパーメソッド ★★★
    func generateResult(from quizResult: QuizResult) async -> ResultData {
        let accuracy = Double(quizResult.score) / Double(quizResult.totalQuestions)
        let evaluation = determineEvaluation(for: accuracy)
        
        let primaryAction = ResultAction(type: .backToHome, isPrimary: true)
        var secondaryActions: [ResultAction] = []
        
        let allQuestions = (try? await DataService.shared.getAllQuestions()) ?? []
        let incorrectQuestions = quizResult.incorrectQuestionIDs.compactMap { id in
            allQuestions.first(where: { $0.id == id })
        }
        
        if !incorrectQuestions.isEmpty {
            secondaryActions.insert(ResultAction(type: .reviewMistakes, isPrimary: false), at: 0)
        }
        
        let reviewableItems = incorrectQuestions.map { ResultReviewItem(question: $0, userAnswer: nil, isCorrect: false) }
        
        return ResultData(
            score: quizResult.score,
            totalQuestions: quizResult.totalQuestions,
            evaluation: evaluation,
            statistics: [],
            reviewableQuestions: reviewableItems,
            primaryAction: primaryAction,
            secondaryActions: secondaryActions,
            mode: .standard,
            difficulty: nil,
            selectedSkills: nil,
            selectedGenres: nil,
            mistakeTolerance: nil,
            timeLimit: nil,
            selectedCourseIDs: nil,
            mistakeLimit: nil
        )
    }

    /// 正答率から評価（タイトル、メッセージ、色）を決定するヘルパー関数
    func determineEvaluation(for accuracy: Double) -> (title: String, message: String, color: Color) {
        if accuracy >= 1.0 {
            return ("PERFECT!", "素晴らしい！全問正解です！", .pink)
        } else if accuracy >= 0.9 {
            return ("EXCELLENT", "お見事です！ほぼ完璧に理解しています。", .red)
        } else if accuracy >= 0.7 {
            return ("GREAT", "高い正答率です！この調子で頑張りましょう。", .orange)
        } else if accuracy >= 0.5 {
            return ("GOOD", "ナイスチャレンジ！半分以上正解です。", .green)
        } else {
            return ("NICE TRY", "お疲れ様でした。復習がスコアアップの鍵です！", .blue)
        }
    }
}

