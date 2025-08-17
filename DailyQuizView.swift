/*
import SwiftUI

/// 「今日の一問」専用の新しいコンテナView
struct DailyQuizView: View {
    
    @StateObject private var viewModel: DailyQuizViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(question: Question) {
        _viewModel = StateObject(wrappedValue: DailyQuizViewModel(question: question))
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            
            if viewModel.isQuizFinished {
                // 解答後は結果画面を表示
                DailyQuizResultView(
                    isCorrect: viewModel.isCorrect ?? false,
                    question: viewModel.question,
                    onDismiss: { dismiss() }
                )
            } else {
                // 解答前はクイズエンジンを表示
                VStack {
                    // ヘッダー
                    Text("今日の一問")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    // エンジン
                    QuizEngineView(viewModel: viewModel.engineViewModel, onNextQuestion: {dismiss()})
                }
            }
        }
        .navigationTitle("今日の一問")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Reusable Nested UI Components
private struct DailyQuizResultView: View {
    let isCorrect: Bool
    let question: Question
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text(isCorrect ? "正解です！" : "残念、不正解です…")
                .font(.largeTitle.bold())
                .foregroundColor(isCorrect ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("問題： " + question.questionText).font(.headline)
                Divider()
                Text("解説： " + question.explanation)
            }
            .padding().background(DesignSystem.Colors.surfacePrimary).cornerRadius(15)
            
            Spacer()
            
            Button(action: onDismiss) { Text("ホームに戻る") }.buttonStyle(PrimaryButtonStyle())
        }
        .padding(30)
    }
}
*/