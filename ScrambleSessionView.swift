import SwiftUI

struct ScrambleSessionView: View {
    @StateObject private var viewModel: ScrambleSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showReviewSession = false

    init(questions: [SyntaxScrambleQuestion]) {
        _viewModel = StateObject(wrappedValue: ScrambleSessionViewModel(questions: questions))
    }
    
    private var incorrectQuestions: [SyntaxScrambleQuestion] {
        viewModel.sessionResults.filter { !$0.isCorrect }.map { $0.question }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー（プログレスバーと閉じるボタン）
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
                ProgressView(value: viewModel.progress)
                Text("\(viewModel.currentQuestionIndex + 1)/\(viewModel.questions.count)")
            }
            .padding()
            
            // 問題表示部分
            TabView(selection: $viewModel.currentQuestionIndex) {
                ForEach(viewModel.questions.indices, id: \.self) { index in
                    ScrambleQuizView(
                        question: viewModel.questions[index],
                        currentIndex: viewModel.currentQuestionIndex,
                        totalQuestions: viewModel.questions.count,
                        onComplete: { isCorrect in
                            await viewModel.recordResult(question: viewModel.questions[index], isCorrect: isCorrect)
                            viewModel.goToNextQuestion()
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // ページインジケータは非表示
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showResultView) {
            UnifiedResultView(resultData: viewModel.createResultData(), isNewRecord: false) { action in
                handleResultAction(action)
            }
        }
        .fullScreenCover(isPresented: $showReviewSession) {
            ScrambleSessionView(questions: incorrectQuestions)
        }
    }

    private func handleResultAction(_ action: ResultActionType) {
        switch action {
        case .backToHome:
            dismiss()
        case .reviewMistakes:
            if !incorrectQuestions.isEmpty {
                viewModel.showResultView = false
                showReviewSession = true
            } else {
                dismiss()
            }
        default:
            dismiss()
        }
    }
}
