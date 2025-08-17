import SwiftUI

/// 新しい「クイズ付き単語レッスン」のメイン画面
struct VocabularyLessonQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingExitAlert = false
    
    let vocabSet: VocabularyQuizSet
    let onQuizCompleted: (() -> Void)?
    let accentColor: Color // 新しく追加

    @StateObject private var viewModel: VocabularyLessonQuizViewModel
    
    // initを追加
    init(vocabSet: VocabularyQuizSet, onQuizCompleted: (() -> Void)?, accentColor: Color) {
        let initialVocabSet = vocabSet
        let initialOnQuizCompleted = onQuizCompleted
        let initialAccentColor = accentColor

        self.vocabSet = initialVocabSet
        self.onQuizCompleted = initialOnQuizCompleted
        self.accentColor = initialAccentColor
        
        // Create a non-optional version of the completion handler
        let completionHandler: () -> Void = initialOnQuizCompleted ?? {}
        // _viewModelを初期化し、modelContextを渡す
        _viewModel = StateObject(wrappedValue: VocabularyLessonQuizViewModel(vocabSet: initialVocabSet, onQuizCompleted: completionHandler))
    }

    

    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: [accentColor, DesignSystem.Colors.backgroundPrimary])

            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button(action: {
                        isShowingExitAlert = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        // viewModelが非Optionalなので直接アクセス
                        ProgressView(value: viewModel.progress)
                            .tint(DesignSystem.Colors.brandPrimary)
                        Text("\(viewModel.currentIndex + 1) / \(viewModel.vocabSet.questions.count)")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                if !viewModel.isFinished {
                    FlashcardQuiz(
                        question: viewModel.currentQuestion,
                        onAnswer: viewModel.handleAnswer,
                        onNext: { await viewModel.moveToNextOrFinish() },
                        isReviewed: viewModel.isCurrentQuestionReviewed,
                        toggleReviewStatus: { await viewModel.toggleReviewStatus() }
                    )
                    .id(viewModel.currentQuestion.id)
                }
            }
            .padding(.bottom)
        }
        .navigationBarHidden(true)
        // viewModelが非Optionalなので$viewModel.resultDataを直接使用
        .fullScreenCover(item: $viewModel.resultData) { resultData in
            NavigationView {
                UnifiedResultView(resultData: resultData, isNewRecord: false, onAction: { _ in
                    viewModel.resultData = nil // 直接アクセス
                    dismiss()
                    self.onQuizCompleted?()
                })
            }
        }
        // viewModelが非OptionalなのでviewModel.isFinishedを直接使用
        .onChange(of: viewModel.isFinished) {
            if viewModel.isFinished {
                Task {
                    await viewModel.prepareAndShowResult()
                }
            }
        }
        
        
        .onAppear {
            Task {
                await viewModel.setModelContext(modelContext) // ここでmodelContextを設定
            }
        }
        
        .alert("レッスンを中断しますか？", isPresented: $isShowingExitAlert) {
            Button("中断する", role: .destructive) {
                dismiss()
            }
            Button("続ける", role: .cancel) {}
        } message: {
            Text("ここまでの進捗は記録されません。")
        }
    }
}


// MARK: - FlashcardQuiz (内側の部品)
private struct FlashcardQuiz: View {
    let question: VocabularyQuestion
    let onAnswer: (Bool, Int?) async -> Void
    let onNext: () async -> Void
    let isReviewed: Bool // 追加
    let toggleReviewStatus: () async -> Void // 追加

    @State private var selectedOptionIndex: Int?
    @State private var isAnswered = false
    @State private var isFlipped = false
    @State private var rotation: Double = 0
    
    private var isCorrect: Bool {
        guard let selectedOptionIndex = selectedOptionIndex else { return false }
        return selectedOptionIndex == question.correctAnswerIndex
    }
    
    var body: some View {
        ZStack {
            quizSide.opacity(isFlipped ? 0 : 1)
            explanationSide.opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0.0, y: 1.0, z: 0.0))
    }
    
    // MARK: - 表面：クイズUI
    @ViewBuilder
        private var quizSide: some View {
            VStack(spacing: 20) {
                Text(question.questionText)
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                VStack(spacing: 12) {
                    ForEach(question.options.indices, id: \.self) { index in
                        Button(action: { Task { await selectOption(at: index) } }) {
                            HStack(spacing: 16) {
                                Text(String(format: "%c", 65 + index))
                                    .font(.headline.bold())
                                    .foregroundColor(DesignSystem.Colors.brandPrimary)
                                    .frame(width: 20)
                                Text(question.options[index])
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(OptionButtonStyle(
                            isSubmitted: isAnswered,
                            isSelected: index == selectedOptionIndex,
                            isCorrect: index == question.correctAnswerIndex
                        ))
                        .disabled(isAnswered)
                    }
                }
            }
            .padding()
            .background(DesignSystem.Colors.surfacePrimary)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
        }

    // MARK: - 裏面：解説UI
    @ViewBuilder
    private var explanationSide: some View {
        ScrollView {
            // ★★★ 解決策1: 複雑なUIを小さな部品に分割 ★★★
            VStack(alignment: .leading, spacing: 25) {
                feedbackHeader
                questionReviewSection
                keyPointSection
                exampleSentenceSection // 追加
                exampleSentenceTranslationSection
                relatedExpressionsSection // 追加
                actionButtonsSection
            }
            .padding(25)
        }
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
    }

    // MARK: - 裏面UIの小さな部品
    @ViewBuilder
    private var feedbackHeader: some View {
        HStack {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isCorrect ? .green : .red)
            Text(isCorrect ? "正解！" : "不正解...")
                .font(.title2.bold())
                .foregroundColor(isCorrect ? .green : .red)
        }
    }
    
    @ViewBuilder
    private var questionReviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.questionText)
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            HStack {
                Text("正解：")
                    .font(.headline)
                Text("(\(String(format: "%c", 65 + question.correctAnswerIndex))) \(question.options[question.correctAnswerIndex])")
                    .font(.headline.bold())
                    .foregroundColor(DesignSystem.Colors.brandPrimary)
            }
        }
    }
    
    @ViewBuilder
    private var keyPointSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔑 ポイント解説").font(.headline)
            Text(question.explanation)
        }
    }

    @ViewBuilder
    private var deepDiveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📚 単語深掘り").font(.headline)
            HStack {
                Text(question.word).font(.title.bold())
            }
        }
    }

    @ViewBuilder
    private var exampleSentenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📝 例文").font(.headline)
            Text(question.exampleSentence)
                .font(.body)
                .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private var exampleSentenceTranslationSection: some View {
        if let translation = question.exampleSentenceTranslation, !translation.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("🇯🇵 例文の日本語訳").font(.headline)
                Text(translation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var relatedExpressionsSection: some View {
        if let expressions = question.relatedExpressions, !expressions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 関連表現").font(.headline)
                ForEach(expressions, id: \.self) { expression in
                    Text("・ \(expression)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Button(action: { Task { await toggleReviewStatus() } }) {
            //     Label(isReviewed ? "苦手な単語から解除" : "苦手な単語として登録", systemImage: isReviewed ? "star.fill" : "star")
            // }
            // .buttonStyle(SecondaryButtonStyle())
            // .disabled(isAnswered) // この行を削除またはコメントアウト
            
            Button(action: { Task { await onNext() } }) {
                Label("次へ", systemImage: "arrow.right")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top)
    }

    // MARK: - Logic
    private func selectOption(at index: Int) async {
        guard !isAnswered else { return }
        isAnswered = true
        selectedOptionIndex = index
        HapticManager.softTap()
        
        await onAnswer(index == question.correctAnswerIndex, selectedOptionIndex)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                rotation += 180
                isFlipped = true
            }
            if isCorrect {
                HapticManager.shared.playSuccess()
            } else {
                HapticManager.shared.playError()
            }
        }
    }
}

fileprivate struct OptionButtonStyle: ButtonStyle {
    let isSubmitted: Bool
    let isSelected: Bool
    let isCorrect: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundColor(.primary)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        if !isSubmitted {
            return isPressed ? Color.gray.opacity(0.15) : DesignSystem.Colors.surfacePrimary
        }
        
        if isSelected {
            return isCorrect ? .green.opacity(0.7) : .red.opacity(0.6)
        } else {
            return isCorrect ? .green.opacity(0.7) : DesignSystem.Colors.surfacePrimary
        }
    }
}
