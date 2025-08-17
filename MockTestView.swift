import SwiftUI
import SwiftData

// New ButtonStyle for Tertiary (outline) button - Moved to top-level
struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Fonts.headline.bold())
            .foregroundColor(DesignSystem.Colors.brandPrimary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: DesignSystem.Elements.cornerRadius).stroke(DesignSystem.Colors.brandPrimary, lineWidth: 2))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// ReviewQuizView - Moved to top-level
struct ReviewQuizView: View {
    let questions: [Question]
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                Text("間違えた問題の復習")
                    .font(.largeTitle.bold())
                    .padding()
                
                if questions.isEmpty {
                    Text("間違えた問題はありませんでした！")
                        .foregroundColor(.secondary)
                } else {
                    List(questions) { question in
                        VStack(alignment: .leading) {
                            Text(question.questionText)
                                .font(.headline)
                            Text("正解: \(question.options[question.correctAnswerIndex])")
                                .foregroundColor(.green)
                            Text("解説: \(question.explanation)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let category = question.category {
                                Text("#\(category)")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 4)
                                    .background(Capsule().fill(Color.blue.opacity(0.2)))
                            }
                        }
                    }
                }
                
                Button("閉じる", action: onDismiss)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
            }
            .navigationTitle("復習")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// New ResultActionsView for bottom sheet
struct ResultActionsView: View {
    let onReviewIncorrect: () -> Void
    let onTryAgain: () -> Void
    let onAnalyzeWeakAreas: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onReviewIncorrect) {
                Label("間違えた問題だけ復習する", systemImage: "arrow.clockwise.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(action: onTryAgain) {
                Label("もう一度挑戦する", systemImage: "arrow.counterclockwise.circle.fill")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(action: onAnalyzeWeakAreas) {
                HStack {
                    Label("苦手分野を分析する", systemImage: "chart.bar.xaxis")
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(action: onDismiss) {
                Text("模試選択に戻る")
            }
            .buttonStyle(TertiaryButtonStyle())
        }
        .padding()
    }
}

/// 模試専用の新しいコンテナView
struct MockTestView: View {
    
    @StateObject private var viewModel: MockTestViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingQuestionJumper = false
    @State private var showMarkReviewHint = false
    @State private var showExitConfirmation = false
    
    init(session: MockTestSession, questions: [Question]) {
        _viewModel = StateObject(wrappedValue: MockTestViewModel(session: session, questions: questions)!)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
                
                switch viewModel.phase {
                case .takingTest:
                    mainQuizView(viewModel: viewModel)
                case .scoring:
                    scoringView(viewModel: viewModel, modelContext: modelContext, dismiss: dismiss, sessionRemainingTime: viewModel.sessionRemainingTime)
                case .finished:
                    // 元のQuizViewから結果表示部分を流用
                    MockTestResultView(
                        score: viewModel.score,
                        highestScore: viewModel.highestScore,
                        totalQuestions: viewModel.originalQuestions.count,
                        questions: viewModel.originalQuestions,
                        userAnswers: viewModel.userAnswers,
                        markedQuestions: viewModel.markedQuestions, // Pass markedQuestions
                        onDismiss: {
                            MockTestManager.shared.clearCurrentSession()
                            dismiss()
                        },
                        onTryAgain: viewModel.resetForRetry
                    )
                }
            }
            .navigationTitle("Part5 模試")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                if viewModel.phase == .takingTest {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showExitConfirmation = true }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.toggleMarkForReview(questionId: viewModel.currentQuestion.id)
                        }) {
                            Image(systemName: viewModel.markedQuestions.contains(viewModel.currentQuestion.id) ? "flag.fill" : "flag")
                                .font(.title2)
                                .foregroundColor(viewModel.markedQuestions.contains(viewModel.currentQuestion.id) ? .orange : .secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingQuestionJumper) {
                    QuestionJumpView(
                        totalQuestions: viewModel.originalQuestions.count,
                        userAnswers: viewModel.userAnswers,
                        questionIDs: viewModel.originalQuestions.map { $0.id },
                        markedQuestions: viewModel.markedQuestions,
                        onSelectQuestion: { index in
                            viewModel.jumpToQuestion(index: index)
                            isShowingQuestionJumper = false
                        },
                        onDismiss: { isShowingQuestionJumper = false }
                    )
                }
            
            if showMarkReviewHint {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("この旗で後で見直す問題をマークできます")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                            Image(systemName: "arrow.down.right.circle.fill")
                                .foregroundColor(.white)
                                .font(.title)
                                .offset(x: -10, y: -5)
                        }
                        .padding(.trailing, 10)
                        .padding(.top, 50) // Adjust position to point to the flag
                    }
                    .onTapGesture {
                        withAnimation { showMarkReviewHint = false }
                    }
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeIn, value: showMarkReviewHint)
            }
        }
        .onAppear {
            // Show hint for a few seconds
            showMarkReviewHint = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { showMarkReviewHint = false }
            }
        }
        .alert("模試を中断しますか？", isPresented: $showExitConfirmation) {
            Button("中断して終了", role: .destructive) {
                MockTestManager.shared.clearCurrentSession()
                dismiss()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("現在の模試の進行状況は失われます。")
        }
    }
    
    // MARK: - UI Sections
    
    private func mainQuizView(viewModel: MockTestViewModel) -> some View {
        VStack(spacing: 20) {
            // 模試専用ヘッダー
            MockTestHeader(
                currentQuestionIndex: viewModel.currentQuestionIndex,
                totalQuestions: viewModel.originalQuestions.count,
                remainingTime: viewModel.sessionRemainingTime,
                onTapJumper: { isShowingQuestionJumper = true }
            )
            
            // 問題文
            Text(viewModel.currentQuestion.questionText)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 100)

            // 模試専用の選択肢リスト
            MockOptionsListView(viewModel: viewModel)
            
            // 前へ・次へボタン
            HStack {
                Button(action: { viewModel.moveToPreviousQuestion() }) {
                    Label("前へ", systemImage: "arrow.left")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(viewModel.currentQuestionIndex == 0)
                
                Button(action: { viewModel.moveToNextQuestion() }) {
                    if viewModel.currentQuestionIndex == viewModel.originalQuestions.count - 1 {
                        Text("採点する")
                    } else {
                        HStack {
                            Text("次へ")
                            Image(systemName: "arrow.right")
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
    }
    
    // 元のQuizViewから採点画面を流用
    private func scoringView(viewModel: MockTestViewModel, modelContext: ModelContext, dismiss: DismissAction, sessionRemainingTime: Int) -> some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "checklist.checked")
                .font(.system(size: 80))
                .foregroundColor(.green)
            Text("テストを提出しますか？")
                .font(.largeTitle.bold())
            Text(sessionRemainingTime > 0 ? "お疲れ様でした。まだ時間があります。提出前に解答を見直すこともできます。" : "時間です！お疲れ様でした。結果を確認しましょう。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: {
                viewModel.finalizeAndScore(context: modelContext)
            }) {

                Label("採点して結果を見る", systemImage: "checkmark.circle.fill")
                    .font(DesignSystem.Fonts.headline.bold())
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.brandPrimary.gradient)
                    .cornerRadius(DesignSystem.Elements.cornerRadius)
            }
            
            Button(action: {
                viewModel.phase = .takingTest // Go back to taking test phase
            }) {
                Text("解答に戻って見直す")
            }
            .buttonStyle(TertiaryButtonStyle())
        }
        .padding(40)
    }
}


// MARK: - Mock Test Specific Components

private struct MockTestHeader: View {
    let currentQuestionIndex: Int
    let totalQuestions: Int
    let remainingTime: Int
    let onTapJumper: () -> Void
    
    private var progress: Double {
        return Double(currentQuestionIndex) / Double(totalQuestions - 1)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onTapJumper) {
                    HStack {
                        Text("\(currentQuestionIndex + 1) / \(totalQuestions) 問")
                        Image(systemName: "square.grid.2x2.fill")
                    }
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: "stopwatch.fill")
                    Text(String(format: "%02d:%02d", remainingTime / 60, remainingTime % 60))
                }
                .font(.headline.monospacedDigit()).foregroundColor(remainingTime <= 60 ? .red : .purple)
            }
            ProgressView(value: progress)
        }
    }
}

private struct QuestionJumpView: View {
    let totalQuestions: Int
    let userAnswers: [String: Int]
    let questionIDs: [String]
    let markedQuestions: Set<String>
    let onSelectQuestion: (Int) -> Void
    let onDismiss: () -> Void
    
    private let columns = [GridItem(.adaptive(minimum: 60))]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(0..<totalQuestions, id: \.self) { index in
                        Button(action: { onSelectQuestion(index) }) {
                            ZStack(alignment: .topTrailing) {
                                Text("\(index + 1)")
                                    .font(.title2)
                                    .frame(width: 60, height: 60)
                                    .background(userAnswers[questionIDs[index]] != nil ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(10)
                                
                                if markedQuestions.contains(questionIDs[index]) {
                                    Image(systemName: "flag.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .offset(x: 5, y: -5)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("問題一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("問題一覧")
                        Text("解答済み: \(userAnswers.count) / \(totalQuestions)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onDismiss)
                }
            }
        }
    }
}

private struct MockOptionsListView: View {
    @ObservedObject var viewModel: MockTestViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<viewModel.currentQuestion.options.count, id: \.self) { index in
                Button(action: { viewModel.selectAnswer(answerIndex: index) }) {
                    HStack {
                        Text(String(format: "%c", 65 + index))
                        Text(viewModel.currentQuestion.options[index])
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(index == viewModel.userAnswers[viewModel.currentQuestion.id] ? DesignSystem.Colors.brandPrimary : DesignSystem.Colors.surfacePrimary)
                    .foregroundColor(index == viewModel.userAnswers[viewModel.currentQuestion.id] ? .white : .primary)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                }
            }
        }
    }
}



struct MockTestResultView: View {
    let score: Int
    let highestScore: Int
    let totalQuestions: Int
    let questions: [Question]
    let userAnswers: [String: Int]
    let markedQuestions: Set<String> // Added markedQuestions
    let onDismiss: () -> Void
    let onTryAgain: () -> Void

    init(score: Int, highestScore: Int, totalQuestions: Int, questions: [Question], userAnswers: [String: Int], markedQuestions: Set<String>, onDismiss: @escaping () -> Void, onTryAgain: @escaping () -> Void) {
        self.score = score
        self.highestScore = highestScore
        self.totalQuestions = totalQuestions
        self.questions = questions
        self.userAnswers = userAnswers
        self.markedQuestions = markedQuestions
        self.onDismiss = onDismiss
        self.onTryAgain = onTryAgain
    }

    // Force recompile

    @State private var showReviewQuiz = false
    @State private var showWeaknessAnalysis = false
    @State private var showPaywall = false
    @State private var showActionSheet = false // New state for action sheet
    @State private var showQuestionReviewDetail = false // New state for showing the detail view
    @State private var selectedQuestionIndex: Int = 0 // New state to hold the index of the selected question

    enum FilterType: String, CaseIterable, Identifiable {
        case all = "すべて"
        case correct = "正解"
        case incorrect = "不正解"
        case flagged = "フラグ付き"

        var id: String { self.rawValue }
    }

    @State private var selectedFilter: FilterType = .all

    private var accuracy: Double {
        totalQuestions > 0 ? Double(score) / Double(totalQuestions) : 0
    }
    
    private var feedbackMessage: String {
        if accuracy >= 0.95 {
            return "素晴らしいスコアです！完璧まであと一歩。間違えた問題を確実にマスターしましょう！"
        } else if accuracy >= 0.8 {
            return "よくできました！間違えた問題を復習すれば、さらにスコアアップが狙えます！"
        } else if accuracy >= 0.5 {
            return "お疲れ様でした！良いスコアですね。間違えた問題を復習すれば、さらにスコアアップが狙えます！"
        } else {
            return "お疲れ様でした！今は伸びしろだらけです。まずは間違えた問題の解説をじっくり読んで、一つずつ確実に理解することから始めましょう。"
        }
    }
    
    private var filteredQuestions: [Question] {
        questions.filter { question in
            let isCorrect = userAnswers[question.id] == question.correctAnswerIndex
            switch selectedFilter {
            case .all: return true
            case .correct: return isCorrect
            case .incorrect: return !isCorrect
            case .flagged: return markedQuestions.contains(question.id)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("模試終了！")
                .font(.largeTitle.bold())
            
            Text("あなたのスコア")
                .font(.title2)
            
            Text("\(score) / \(totalQuestions)")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(score > (totalQuestions / 2) ? .green : .orange)
            
            if score > highestScore {
                Text("🎉 自己ベスト更新！")
                    .font(.headline)
                    .foregroundColor(.yellow)
            } else if highestScore > 0 {
                Text("自己ベスト: \(highestScore) / \(totalQuestions)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(feedbackMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Picker("Filter", selection: $selectedFilter) {
                ForEach(FilterType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal) // Add horizontal padding to the picker

            List {
                Section(header: Text("結果の詳細")) {
                    ForEach(filteredQuestions.indices, id: \.self) { index in
                        let question = filteredQuestions[index]
                        let userAnswerIndex = userAnswers[question.id]
                        let isCorrect = userAnswerIndex == question.correctAnswerIndex
                        
                        Button(action: {
                            showQuestionReviewDetail = true
                            selectedQuestionIndex = index
                        }) {
                            HStack {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrect ? .green : .red)
                                Text("問題 \(questions.firstIndex(where: { $0.id == question.id })! + 1)") // Use original index
                                Text(question.questionText)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.secondary)
                                if let category = question.category {
                                    Text("#\(category)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 4)
                                        .background(Capsule().fill(Color.blue.opacity(0.2)))
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            
            // MARK: - Action Button to show bottom sheet
            Button(action: { showActionSheet = true }) {
                Text("次のアクション")
                    .font(DesignSystem.Fonts.headline.bold())
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.brandPrimary.gradient)
                    .cornerRadius(DesignSystem.Elements.cornerRadius)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .sheet(isPresented: $showReviewQuiz) {
            let incorrectQuestions = questions.filter { userAnswers[$0.id] != $0.correctAnswerIndex }
            ReviewQuizView(questions: incorrectQuestions, onDismiss: { showReviewQuiz = false })
        }
        .sheet(isPresented: $showWeaknessAnalysis) {
            // Placeholder for WeaknessAnalysisView
            Text("Weakness Analysis View will go here")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showActionSheet) {
            ResultActionsView(
                onReviewIncorrect: {
                    showReviewQuiz = true
                    showActionSheet = false
                },
                onTryAgain: {
                    onTryAgain()
                    showActionSheet = false
                },
                onAnalyzeWeakAreas: {
                    if SettingsManager.shared.isPremiumUser {
                        showWeaknessAnalysis = true
                    } else {
                        showPaywall = true
                    }
                    showActionSheet = false
                },
                onDismiss: {
                    onDismiss() // Dismiss MockTestResultView
                    showActionSheet = false
                }
            )
            .presentationDetents([.medium, .large]) // Make it a true bottom sheet
        }
        .sheet(isPresented: $showQuestionReviewDetail) {
            QuestionReviewDetailView(
                questions: filteredQuestions,
                userAnswers: userAnswers,
                markedQuestions: markedQuestions,
                initialQuestionIndex: selectedQuestionIndex,
                onDismiss: { showQuestionReviewDetail = false }
            )
        }
    }
}