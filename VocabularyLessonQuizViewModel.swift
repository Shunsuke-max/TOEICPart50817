import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class VocabularyLessonQuizViewModel: ObservableObject {
    
    @Published var currentIndex = 0
    @Published var isFinished = false
    @Published var resultData: ResultData? = nil
    @Published var isCurrentQuestionReviewed: Bool = false

    let vocabSet: VocabularyQuizSet // クラスのプロパティとして宣言
    
    var progress: CGFloat {
        guard !vocabSet.questions.isEmpty else { return 0 }
        return CGFloat(currentIndex) / CGFloat(vocabSet.questions.count)
    }
    
    var currentQuestion: VocabularyQuestion {
        guard currentIndex < vocabSet.questions.count else {
            fatalError("currentIndex out of bounds")
        }
        return vocabSet.questions[currentIndex]
    }
    
    private var score = 0 // クラスのプロパティとして宣言
    private var incorrectQuestions: [VocabularyQuestion] = [] // クラスのプロパティとして宣言
    private var userSelectedAnswers: [String: Int] = [:] // 新しく追加
    
    private let resultViewModel = ResultViewModel() // クラスのプロパティとして宣言
    private var cancellable: AnyCancellable? // クラスのプロパティとして宣言
    private var startTime: Date! // クラスのプロパティとして宣言
    private let onQuizCompleted: () -> Void // クラスのプロパティとして宣言
    private lazy var reviewManager: ReviewManager = ReviewManager()
    private var modelContext: ModelContext?

    init(vocabSet: VocabularyQuizSet, onQuizCompleted: @escaping () -> Void) {
        var mutableVocabSet = vocabSet
        mutableVocabSet.questions = vocabSet.questions.shuffled().map { $0.shuffled() }
        self.vocabSet = mutableVocabSet
        self.startTime = Date()
        self.onQuizCompleted = onQuizCompleted

        cancellable = resultViewModel.$resultData.sink { [weak self] data in
            self?.resultData = data
        }
    }
    
    // modelContextを設定するメソッドを追加
    func setModelContext(_ context: ModelContext) async {
        self.modelContext = context
        await checkReviewStatus() // modelContextが設定された後に呼び出す
    }
    

    
    
    
    
    
    func handleAnswer(isCorrect: Bool, selectedAnswerIndex: Int?) async {
        if isCorrect {
            score += 1
            guard let modelContext = modelContext else { return }
            await reviewManager.updateReviewItem(questionID: currentQuestion.id, quality: 5, modelContext: modelContext)
        } else {
            guard let modelContext = modelContext else { return }
            incorrectQuestions.append(currentQuestion)
            await reviewManager.updateReviewItem(questionID: currentQuestion.id, quality: 0, modelContext: modelContext)
        }
        // ユーザーの選択した解答を保存
        if let selectedAnswerIndex = selectedAnswerIndex {
            userSelectedAnswers[currentQuestion.id] = selectedAnswerIndex
        }
    }
    
    func moveToNextOrFinish() async {
        if currentIndex < vocabSet.questions.count - 1 {
            withAnimation {
                currentIndex += 1
            }
            await checkReviewStatus() // modelContext引数を削除
        } else {
            isFinished = true
        }
    }
    
    // 苦手な単語の登録/解除を切り替えるメソッド
    func toggleReviewStatus() async {
        let questionID = currentQuestion.id
        // qualityはユーザーが明示的に苦手とマークした場合なので、0とする
        guard let modelContext = modelContext else { return }

        if isCurrentQuestionReviewed {
            // 既に苦手な単語として登録されている場合、解除する
            await reviewManager.deleteReviewItem(questionID: questionID, modelContext: modelContext)
        } else {
            // 苦手な単語として登録する (quality: 0 は「全く思い出せない」を意味する)
            await reviewManager.updateReviewItem(questionID: questionID, quality: 0, modelContext: modelContext)
        }
        // 状態を更新
        isCurrentQuestionReviewed = await reviewManager.reviewItemExists(questionID: questionID, modelContext: modelContext)
    }
    
    // 現在の問題の復習状態を確認するプライベートメソッド
    private func checkReviewStatus() async { // modelContext引数を削除
        guard let modelContext = modelContext else { return }
        isCurrentQuestionReviewed = await reviewManager.reviewItemExists(questionID: currentQuestion.id, modelContext: modelContext)
    }
    
    func prepareAndShowResult() async { // context引数を削除
        // --- 1. 結果をデータベースに保存 ---
        await saveResultToDB() // context引数を削除
        
        // --- 2. 表示用のデータを生成 ---
        let standardIncorrectQuestions = incorrectQuestions.map { $0.toQuestion() }
        let allStandardQuestions = vocabSet.questions.map { $0.toQuestion() }

        resultViewModel.generateResult(
            score: self.score,
            totalQuestions: vocabSet.questions.count,
            incorrectQuestions: standardIncorrectQuestions,
            allQuestionsInQuiz: allStandardQuestions, // ★★★ 全問題リストを渡す ★★★
            mode: .vocabularyLesson, // ★★★ モードを明示的に指定 ★★★
            statistics: [], // 明示的に空の配列を渡す
            userSelectedAnswers: userSelectedAnswers // 新しく追加
        )
    }
    
    private func saveResultToDB() async { // context引数を削除
        guard let modelContext = modelContext else { return }
        let elapsedTime = Date().timeIntervalSince(startTime) // 経過時間を計算
        
        let newResult = QuizResult(
            id: UUID(),
            setId: vocabSet.setId,
            score: self.score,
            totalQuestions: vocabSet.questions.count,
            date: Date(),
            incorrectQuestionIDs: incorrectQuestions.map { $0.id },
            duration: elapsedTime // 計算した経過時間を設定
        )
        modelContext.insert(newResult)
        do {
            try modelContext.save() // データを永続化
        } catch {
            print("❌ Failed to save QuizResult: \(error)")
        }
        
        StudyTimeManager.shared.add(time: elapsedTime) // 学習時間を追加
        _ = UserStatsManager.shared.addXP(50)
        QuizCompletionNotifier.shared.quizDidComplete.send()
        
        
        // 全問完了したら次のセットをアンロック
        if score == vocabSet.questions.count {
            // ここで全VocabularyQuizSetのリストが必要になるが、ViewModelは単一のvocabSetしか持たない
            // そのため、VocabularyCourseViewModelからこのメソッドを呼び出すか、
            // SettingsManager.shared.unlockNextVocabularySetにallSetsを渡す必要がある
            // 今回は簡易的に、SettingsManagerにallSetsを渡す形で進める
            // TODO: より良い設計を検討
            // SettingsManager.shared.unlockNextVocabularySet(currentSetId: vocabSet.setId, allSets: /* allSets */)
            // 現状は、VocabularyCourseViewModelがfetchVocabularyCourseを呼び出す際に、
            // isUnlockedを再計算する仕組みなので、明示的にアンロックをトリガーする必要はない
            // ただし、ユーザーにアンロックされたことを通知するUIは必要になる
        }
        
        print("✅ Vocabulary Lesson Result Saved: \(score)/\(vocabSet.questions.count)")
    }
}

