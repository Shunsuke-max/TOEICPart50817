
import SwiftUI

struct QuestionReviewDetailView: View {
    let questions: [Question]
    let userAnswers: [String: Int]
    let markedQuestions: Set<String>
    let onDismiss: () -> Void

    @State private var currentQuestionIndex: Int

    init(questions: [Question], userAnswers: [String: Int], markedQuestions: Set<String>, initialQuestionIndex: Int, onDismiss: @escaping () -> Void) {
        self.questions = questions
        self.userAnswers = userAnswers
        self.markedQuestions = markedQuestions
        self.onDismiss = onDismiss
        _currentQuestionIndex = State(initialValue: initialQuestionIndex)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if questions.isEmpty {
                    Text("問題がありません。")
                        .foregroundColor(.secondary)
                } else {
                    let question = questions[currentQuestionIndex]
                    let userAnswerIndex = userAnswers[question.id]
                    let isCorrect = userAnswerIndex == question.correctAnswerIndex

                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            // Question Number
                            Text("問題 \(questions.firstIndex(where: { $0.id == question.id })! + 1) / \(questions.count)")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            // Question Text
                            Text(question.questionText)
                                .font(.title2.bold())
                                .padding(.bottom, 5)

                            // Options
                            ForEach(question.options.indices, id: \.self) { optionIndex in
                                HStack {
                                    if optionIndex == question.correctAnswerIndex {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else if optionIndex == userAnswerIndex {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.secondary)
                                    }
                                    Text(question.options[optionIndex])
                                        .foregroundColor(optionIndex == question.correctAnswerIndex ? .green : (optionIndex == userAnswerIndex ? .red : .primary))
                                }
                                .padding(.vertical, 2)
                            }

                            Divider()

                            // Explanation
                            Text("解説")
                                .font(.headline)
                            Text(question.explanation)
                                .font(.body)
                                .padding(.bottom, 10)
                        }
                        .padding()
                    }

                    // Navigation Buttons
                    HStack {
                        Button(action: {
                            if currentQuestionIndex > 0 {
                                currentQuestionIndex -= 1
                            }
                        }) {
                            Label("前へ", systemImage: "arrow.left")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(currentQuestionIndex == 0)

                        Spacer()

                        Button(action: {
                            if currentQuestionIndex < questions.count - 1 {
                                currentQuestionIndex += 1
                            }
                        }) {
                            Label("次へ", systemImage: "arrow.right")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(currentQuestionIndex == questions.count - 1)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("問題復習")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる", action: onDismiss)
                }
            }
        }
    }
}
