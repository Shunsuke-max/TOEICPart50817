import SwiftUI

struct ScrambleReviewView: View {
    @StateObject private var viewModel = ScrambleReviewViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentQuestionIndex = 0
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("復習問題を準備中...")
            } else if let error = viewModel.error {
                Text("エラーが発生しました: \(error.localizedDescription)")
            } else if viewModel.reviewQuestions.isEmpty {
                noReviewDataView
            } else {
                quizContentView
            }
        }
        .task {
            await viewModel.prepareReviewSession()
        }
    }
    
    @ViewBuilder
    private var quizContentView: some View {
        VStack(spacing: 0) {
            // ヘッダー（閉じるボタンとプログレス）
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(currentQuestionIndex + 1) / \(viewModel.reviewQuestions.count)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // 問題表示部分
            TabView(selection: $currentQuestionIndex) {
                ForEach(viewModel.reviewQuestions.indices, id: \.self) { index in
                    ScrambleQuizView(question: viewModel.reviewQuestions[index], currentIndex: index, totalQuestions: viewModel.reviewQuestions.count, onComplete: { _ in
                        // 1問完了したら、自動で次の問題へ
                        goToNextQuestion()
                    })
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    @ViewBuilder
    private var noReviewDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("復習できる問題がありません")
                .font(.title2.bold())
            Text("まずはステージマップの問題をクリアしましょう！")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { dismiss() }) {
                Text("マップに戻る")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top)
        }
        .padding(30)
    }
    
    private func goToNextQuestion() {
        if currentQuestionIndex < viewModel.reviewQuestions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else {
            // 全ての問題が終わったら画面を閉じる
            dismiss()
        }
    }
}
