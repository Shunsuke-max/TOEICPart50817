import SwiftUI

/// フラッシュカードでの学習と確認クイズへの遷移を管理するView
struct VocabularyLessonView: View {
    let vocabSet: VocabularyQuizSet
    @State private var currentIndex = 0
    @State private var navigateToQuiz = false
    @Environment(\.dismiss) private var dismiss

    var currentQuestion: VocabularyQuestion {
        vocabSet.questions[currentIndex]
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // プログレスバー
                ProgressView(value: Double(currentIndex + 1), total: Double(vocabSet.questions.count))
                    .tint(DesignSystem.Colors.brandPrimary)
                
                Spacer()

                // フラッシュカード
                FlashcardView {
                    // 表: 単語
                    Text(currentQuestion.word)
                        .font(.largeTitle.bold())
                } back: {
                    // 裏: 例文と解説
                    VStack(alignment: .leading, spacing: 15) {
                        Text(currentQuestion.questionText)
                            .font(.headline)
                        Divider()
                        Text(currentQuestion.explanation)
                            .font(.body)
                    }
                    .padding()
                }
                .id(currentQuestion.id) // 問題が変わるたびにViewを再生成

                Spacer()
                
                // ナビゲーションボタン
                HStack {
                    Button(action: goToPrevious) {
                        Image(systemName: "arrow.left.circle.fill")
                    }
                    .font(.largeTitle)
                    .disabled(currentIndex == 0)
                    
                    Spacer()
                    
                    // 最後のカードならクイズ開始ボタン、そうでなければ「次へ」ボタン
                    if currentIndex == vocabSet.questions.count - 1 {
                        Button("確認クイズに進む") {
                            navigateToQuiz = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: 200)
                    } else {
                        Button(action: goToNext) {
                            Text("次へ")
                                .font(.headline.bold())
                        }
                        .frame(minWidth: 120)
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()

                    Button(action: goToNext) {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.largeTitle)
                    .disabled(currentIndex == vocabSet.questions.count - 1)
                }
            }
            .padding(30)
            .background(
                // クイズ遷移用の非表示NavigationLink
                NavigationLink(destination: lessonDestinationView(), isActive: $navigateToQuiz) {
                    EmptyView()
                }
            )
        }
        .navigationTitle(vocabSet.setName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").font(.title3.weight(.bold))
                }
            }
        }
    }
    
    private func goToNext() {
        if currentIndex < vocabSet.questions.count - 1 {
            withAnimation { currentIndex += 1 }
        }
    }
    
    private func goToPrevious() {
        if currentIndex > 0 {
            withAnimation { currentIndex -= 1 }
        }
    }
    
    // クイズ画面への遷移先を生成
    private func lessonDestinationView() -> some View {
        let standardQuestions = vocabSet.questions.map { vq in
            return Question(id: vq.id, questionText: vq.questionText, options: vq.options, correctAnswerIndex: vq.correctAnswerIndex, explanation: vq.explanation, category: nil)
        }
        let standardQuizSet = QuizSet(setId: vocabSet.setId, setName: vocabSet.setName, questions: standardQuestions)
        
        return QuizStartPromptView(specialQuizSet: standardQuizSet)
    }
}
