import SwiftUI
import SwiftData

struct ReviewQuizFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext // modelContextはここで取得

    @StateObject private var viewModel: ReviewQuizViewModel

    // initにmodelContextを追加
    init(reviewItems: [ReviewItem], questions: [Question], modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: ReviewQuizViewModel(reviewItems: reviewItems, questions: questions, modelContext: modelContext))
    }
    
    // onFinishクロージャをプロパティとして定義
    private var onFinishAction: () async -> Void {
        {
            // DB更新処理を実行
            await viewModel.finishReviewSession(context: modelContext)
            // 画面を閉じる
            dismiss()
        }
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            
            if viewModel.isQuizFinished {
                // クイズ終了後の結果・完了画面
                ReviewResultView(onFinish: { Task { await onFinishAction() } }) // プロパティを渡す
            } else {
                // クイズ中の画面
                VStack(spacing: 20) {
                    // ... (QuizViewからUI要素を簡略化して流用)
                    HeaderBar(
                        progress: CGFloat(viewModel.currentQuestionIndex) / CGFloat(viewModel.questions.count),
                        questionNumber: viewModel.currentQuestionIndex + 1,
                        totalQuestions: viewModel.questions.count
                    )
                    
                    Text(viewModel.currentQuestion.questionText)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 100)
                    
                    OptionButtons(
                        options: viewModel.currentQuestion.options,
                        isSubmitted: viewModel.isAnswerSubmitted,
                        selectedAnswerIndex: viewModel.selectedAnswerIndex,
                        correctAnswerIndex: viewModel.currentQuestion.correctAnswerIndex,
                        onSelect: { index in viewModel.selectAnswer(index: index) }
                    )
                    
                    if viewModel.isAnswerSubmitted {
                        feedbackContent
                            .transition(.opacity.animation(.easeInOut(duration: TimeInterval(0.3))))
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .interactiveDismissDisabled() // 下スワイプで閉じられないようにする
    }
    
    // 解説と次の問題へ進むボタン
    private var feedbackContent: some View {
        VStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text("解説").font(.headline)
                Text(viewModel.currentQuestion.explanation)
            }
            .padding().background(DesignSystem.Colors.surfacePrimary).cornerRadius(10)
            
            Button(action: { viewModel.nextQuestion() }) {
                Text(viewModel.currentQuestionIndex + 1 < viewModel.questions.count ? "次の問題へ" : "結果を見る")
                    .font(DesignSystem.Fonts.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.brandPrimary)
                    .cornerRadius(DesignSystem.Elements.cornerRadius)
            }
        }
    }
    
    // --- 以下、このView内で使うためのUIコンポーネント ---
    
    private struct HeaderBar: View {
        let progress: CGFloat
        let questionNumber: Int
        let totalQuestions: Int
        
        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    Text("問題 \(questionNumber) / \(totalQuestions)").font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                }
                ProgressView(value: progress).progressViewStyle(.linear)
            }
        }
    }
    
    private struct OptionButtons: View {
        let options: [String]
        let isSubmitted: Bool
        let selectedAnswerIndex: Int?
        let correctAnswerIndex: Int
        let onSelect: (Int) -> Void
        
        var body: some View {
            VStack(spacing: 12) {
                ForEach(0..<options.count, id: \.self) { index in
                    Button(action: { onSelect(index) }) {
                        HStack {
                            Text(String(format: "%c", 65 + index))
                            Text(options[index])
                            Spacer()
                        }
                    }
                    .buttonStyle(OptionButtonStyle(
                        isSubmitted: isSubmitted,
                        isSelected: index == selectedAnswerIndex,
                        isCorrect: index == correctAnswerIndex
                    ))
                    .disabled(isSubmitted)
                }
            }
        }
    }
    
    struct OptionButtonStyle: ButtonStyle {
        let isSubmitted: Bool
        let isSelected: Bool
        let isCorrect: Bool
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundColor)
                .foregroundColor(.primary)
                .cornerRadius(10)
        }
        
        private var backgroundColor: Color {
            guard isSubmitted else { return DesignSystem.Colors.surfacePrimary }
            if isCorrect { return .green.opacity(0.7) }
            if isSelected { return .red.opacity(0.6) }
            return DesignSystem.Colors.surfacePrimary
        }
    }
    
    // クイズ終了後に表示されるView
    private struct ReviewResultView: View {
        let onFinish: () async -> Void
        
        var body: some View {
            VStack(spacing: 30) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                Text("復習完了！")
                    .font(.largeTitle.bold())
                Text("今日の学習お疲れ様でした.\n結果は次回の復習スケジュールに反映されます。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
                Button(action: {
                    SettingsManager.shared.lastReviewSessionDate = Date()
                    Task {
                        await onFinish()
                    }
                }){
                    Text("ホームに戻る")
                        .font(DesignSystem.Fonts.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(DesignSystem.Colors.brandPrimary)
                        .cornerRadius(DesignSystem.Elements.cornerRadius)
                }
            }
            .padding(40)
        }
    }
}
