import SwiftUI
import SwiftData

struct VocabularyQuizSetSelectionView: View {
    @StateObject private var viewModel: VocabularyCourseViewModel
    @Query private var allResults: [QuizResult]
    
    let levelName: String
    let color: Color
    
    init(levelName: String, vocabJsonFileName: String, color: Color) {
        self.levelName = levelName
        self.color = color
        _viewModel = StateObject(wrappedValue: VocabularyCourseViewModel(fileName: vocabJsonFileName))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [color.opacity(0.2), DesignSystem.Colors.backgroundPrimary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("コースを読み込んでいます...")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            } else {
                mainContentView
            }
        }
        .task {
            await viewModel.fetchVocabularyCourse()
        }
    }
    
    // MARK: - Main Content View
    
    @ViewBuilder
    private var mainContentView: some View {
        let completedCount = viewModel.quizSets.filter { getIsComplete(for: $0.setId) }.count
        let totalCount = viewModel.quizSets.count
        let nextSetId = viewModel.quizSets.first(where: { !getIsComplete(for: $0.setId) })?.setId

        ScrollView {
            VStack(spacing: 16) {
                Text(levelName) // 大きなレベル名を追加
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top, 8) // 上部に少しパディング

                CourseProgressHeaderView(
                    completedCount: completedCount,
                    totalCount: totalCount
                )
                .padding(.horizontal) // 左右のパディングを調整
                .padding(.bottom, 8) // 下部に少しパディング
                
                ForEach(viewModel.quizSets) { vocabSet in
                    let progress = getProgress(for: vocabSet.setId)

                    NavigationLink {
                            QuizContainerView(vocabSet: vocabSet, onQuizCompleted: {
                                handleQuizCompletion(for: vocabSet.setId)
                            }, vocabAccentColor: color)
                        } label: {
                        VocabSetCardView(
                            quizSet: vocabSet,
                            progress: progress,
                            isNextUp: vocabSet.setId == nextSetId,
                            accentColor: color
                        )
                        .overlay(alignment: .trailing) { // 右端に配置
                            if !vocabSet.isUnlocked { // ロックされている場合のみ表示
                                Image(systemName: "lock.fill")
                                    .font(.title2) // サイズを調整
                                    .foregroundColor(DesignSystem.Colors.textSecondary) // 濃いグレー
                                    .padding(.trailing, 16) // 右からのパディング
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!vocabSet.isUnlocked) // ロックされている場合は無効化
                }
                .padding(.horizontal)
            }
        }
        .onReceive(QuizCompletionNotifier.shared.quizDidComplete) { _ in
            // この画面に戻ってきたときに再描画を強制する
            viewModel.objectWillChange.send()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getProgress(for setId: String) -> Double {
        guard let bestResult = allResults.filter({ $0.setId == setId }).max(by: { $0.score < $1.score }),
              bestResult.totalQuestions > 0 else {
            return 0.0
        }
        return Double(bestResult.score) / Double(bestResult.totalQuestions)
    }
    
    private func getIsComplete(for setId: String) -> Bool {
        return getProgress(for: setId) >= 0.8
    }
    
    private func handleQuizCompletion(for setId: String) {
        SettingsManager.shared.unlockNextVocabularySet(currentSetId: setId, allSets: viewModel.quizSets)
        Task { await viewModel.fetchVocabularyCourse() }
    }
    
    private func destinationView(for vocabSet: VocabularyQuizSet) -> some View {
        let standardQuestions = vocabSet.questions.map { vq in
            return Question(id: vq.id, questionText: vq.questionText, options: vq.options, correctAnswerIndex: vq.correctAnswerIndex, explanation: vq.explanation, category: nil)
        }
        
        let standardQuizSet = QuizSet(
            setId: vocabSet.setId,
            setName: vocabSet.setName,
            questions: standardQuestions
        )
        
        let allStandardSetsInLevel = viewModel.quizSets.map { vSet -> QuizSet in
            let questions = vSet.questions.map { vq -> Question in
                return Question(id: vq.id, questionText: vq.questionText, options: vq.options, correctAnswerIndex: vq.correctAnswerIndex, explanation: vq.explanation, category: nil)
            }
            return QuizSet(setId: vSet.setId, setName: vSet.setName, questions: questions)
        }

        return QuizStartPromptView(specialQuizSet: standardQuizSet, allSets: allStandardSetsInLevel)
    }
}
