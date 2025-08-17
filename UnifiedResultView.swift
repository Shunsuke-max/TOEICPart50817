import SwiftUI

/// 全てのクイズモードで共通して利用できる、統一された結果表示View
struct UnifiedResultView: View {

    let resultData: ResultData
    let isNewRecord: Bool
    let onAction: (ResultActionType) -> Void

    @State private var showingReviewDetail: Bool = false
    @State private var selectedQuestionIndex: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            _ResultHeaderView(
                resultData: resultData,
                isNewRecord: isNewRecord
            )
            
            Spacer()

            _QuestionSummaryListView(
                reviewableQuestions: resultData.reviewableQuestions,
                onSelectQuestion: { index in
                    self.selectedQuestionIndex = index
                    self.showingReviewDetail = true
                }
            )

            _ActionButtonsView(
                resultData: resultData,
                onAction: onAction
            )
        }
        .padding(30)
        .sheet(isPresented: $showingReviewDetail) {
            makeQuestionReviewDetailView()
        }
    }
    
    private func makeQuestionReviewDetailView() -> some View {
        // AnyQuizQuestionのリストをQuestionのリストに変換する
        let questions: [Question] = resultData.reviewableQuestions.map { item in
            if let question = item.question as? Question {
                return question
            } else if let vocabQuestion = item.question as? VocabularyQuestion {
                return vocabQuestion.toQuestion() // 変換メソッドを使用
            } else {
                // 予期しない型の場合、ダミーのQuestionを返すか、エラー処理を行う
                // ここでは解説文だけを持つダミーQuestionを返す
                return Question(id: item.question.id, questionText: "問題データを表示できません", options: [], correctAnswerIndex: 0, explanation: item.question.explanation, category: nil)
            }
        }

        let userAnswersDictionary = Dictionary(
            uniqueKeysWithValues: resultData.reviewableQuestions.compactMap { item -> (String, Int)? in
                return (item.question.id, item.userAnswer ?? -1)
            }
        )
        
        return QuestionReviewDetailView(
            questions: questions,
            userAnswers: userAnswersDictionary,
            markedQuestions: Set<String>(),
            initialQuestionIndex: selectedQuestionIndex,
            onDismiss: { showingReviewDetail = false }
        )
    }
}

// MARK: - Private Helper Views

private struct _ResultHeaderView: View {
    let resultData: ResultData
    let isNewRecord: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(resultData.evaluation.title)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(resultData.evaluation.color)

            VStack {
                Text("SCORE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(resultData.score) / \(resultData.totalQuestions)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
            }
            
            if isNewRecord {
                Label("NEW RECORD!", systemImage: "crown.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.yellow.gradient))
                    .transition(.scale.animation(.spring(response: 0.4, dampingFraction: 0.5)))
            }

            _StatisticsView(statistics: resultData.statistics)
            
            Text(resultData.evaluation.message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

private struct _StatisticsView: View {
    let statistics: [(label: String, value: String)]

    var body: some View {
        if !statistics.isEmpty {
            HStack(spacing: 30) {
                ForEach(statistics, id: \.label) { stat in
                    VStack {
                        Text(stat.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(stat.value)
                            .font(.title.bold())
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(16)
        }
    }
}

private struct _QuestionSummaryListView: View {
    let reviewableQuestions: [ResultReviewItem]
    let onSelectQuestion: (Int) -> Void

    private var correctQuestions: [ResultReviewItem] {
        reviewableQuestions.filter { $0.isCorrect }
    }
    private var incorrectQuestions: [ResultReviewItem] {
        reviewableQuestions.filter { !$0.isCorrect }
    }

    var body: some View {
        if !reviewableQuestions.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !incorrectQuestions.isEmpty {
                        createSection(title: "間違えた問題", items: incorrectQuestions, color: .red)
                    }
                    if !correctQuestions.isEmpty {
                        createSection(title: "正解した問題", items: correctQuestions, color: .green)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 200)
        }
    }

    @ViewBuilder
    private func createSection(title: String, items: [ResultReviewItem], color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(items) { item in
                    if let originalIndex = reviewableQuestions.firstIndex(where: { $0.id == item.id }) {
                        Button(action: { onSelectQuestion(originalIndex) }) {
                            HStack {
                                Text("問題 \(originalIndex + 1)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(item.isCorrect ? .green : .red)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}

private struct _ActionButtonsView: View {
    let resultData: ResultData
    let onAction: (ResultActionType) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: { onAction(resultData.primaryAction.type) }) {
                Label(resultData.primaryAction.type.label, systemImage: resultData.primaryAction.type.icon)
            }
            .buttonStyle(PrimaryButtonStyle())
            
            ForEach(resultData.secondaryActions) { action in
                if action.type != .reviewMistakes {
                    Button(action: { onAction(action.type) }) {
                        Label(action.type.label, systemImage: action.type.icon)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }
}