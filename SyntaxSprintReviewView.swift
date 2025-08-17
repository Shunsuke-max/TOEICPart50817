
import SwiftUI

struct SyntaxSprintReviewView: View {
    @ObservedObject var viewModel: SyntaxSprintViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("問題の復習")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 10)

                    if viewModel.reviewedQuestions.isEmpty {
                        Text("復習する問題がありません。")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.reviewedQuestions) { reviewedQuestion in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("問題: \(reviewedQuestion.question.questionText)")
                                    .font(.headline)

                                Text("あなたの解答:")
                                    .font(.subheadline)
                                Text(reviewedQuestion.userAnswer.map { $0.text }.joined(separator: " "))
                                    .foregroundColor(reviewedQuestion.isCorrect ? .green : .red)

                                Text("正解:")
                                    .font(.subheadline)
                                Text(reviewedQuestion.question.chunks.map { $0.text }.joined(separator: " "))
                                    .foregroundColor(.blue)

                                Text("解説:")
                                    .font(.subheadline)
                                Text(reviewedQuestion.question.explanation)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("復習")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

