import SwiftUI
import SwiftData

/// 新しい設計に基づいた通常クイズのコンテナView
struct StandardQuizView: View {
    
    @StateObject private var viewModel: StandardQuizViewModel
    @StateObject private var resultViewModel = ResultViewModel()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [BookmarkedQuestion]
    
    @State private var navigateToNextSet: QuizSet? = nil
    @State private var startReviewQuiz: Bool = false
    @Query private var allResults: [QuizResult]
    @State private var isNewRecord: Bool = false
    @State private var isShowingExitAlert = false
    let quizDisplayMode: QuizDisplayMode // 新しく追加
    
    private var backgroundColors: [Color] {
        guard let courseColor = viewModel.course?.courseColor else { return [DesignSystem.Colors.backgroundPrimary, DesignSystem.Colors.backgroundPrimary] }
        
        switch quizDisplayMode {
        case .standard:
            return [courseColor, DesignSystem.Colors.backgroundPrimary]
        case .practice:
            return [courseColor.opacity(0.8), DesignSystem.Colors.surfacePrimary]
        case .achievementTest:
            return [courseColor.opacity(0.9), DesignSystem.Colors.backgroundPrimary.opacity(0.7)]
        }
    }
    
    private var backgroundStartPoint: UnitPoint {
        switch quizDisplayMode {
        case .standard: return .topLeading
        case .practice: return .bottomTrailing
        case .achievementTest: return .top
        }
    }
    
    private var backgroundEndPoint: UnitPoint {
        switch quizDisplayMode {
        case .standard: return .bottomTrailing
        case .practice: return .topLeading
        case .achievementTest: return .bottom
        }
    }
    
    
    
    // MARK: - Initializer

    init(quizSet: QuizSet, course: Course?, allSetsInCourse: [QuizSet]?, timeLimit: Int, difficulty: Int? = nil, selectedSkills: [String]? = nil, selectedGenres: [String]? = nil, mistakeTolerance: Int? = nil, quizDisplayMode: QuizDisplayMode = .standard) {
        // 全ての変数を先に宣言
        let initialQuizSet = quizSet
        let initialCourse = course
        let initialAllSetsInCourse = allSetsInCourse
        let initialTimeLimit = timeLimit
        let initialDifficulty = difficulty
        let initialSelectedSkills = selectedSkills
        let initialSelectedGenres = selectedGenres
        let initialMistakeTolerance = mistakeTolerance
        
        // その後でプロパティを設定
        self.quizDisplayMode = quizDisplayMode
        _viewModel = StateObject(wrappedValue: StandardQuizViewModel(
            quizSet: initialQuizSet,
            course: initialCourse,
            allSetsInCourse: initialAllSetsInCourse,
            timeLimit: initialTimeLimit,
            difficulty: initialDifficulty,
            selectedSkills: initialSelectedSkills,
            selectedGenres: initialSelectedGenres,
            mistakeTolerance: initialMistakeTolerance
        ))
    }

    init(specialQuizSet: QuizSet, allSetsInCourse: [QuizSet]? = nil, timeLimit: Int, difficulty: Int? = nil, selectedSkills: [String]? = nil, selectedGenres: [String]? = nil, mistakeTolerance: Int? = nil, quizDisplayMode: QuizDisplayMode = .standard) {
        // 全ての変数を先に宣言
        let initialSpecialQuizSet = specialQuizSet
        let initialAllSetsInCourse = allSetsInCourse
        let initialTimeLimit = timeLimit
        let initialDifficulty = difficulty
        let initialSelectedSkills = selectedSkills
        let initialSelectedGenres = selectedGenres
        let initialMistakeTolerance = mistakeTolerance
        
        // その後でプロパティを設定
        self.quizDisplayMode = quizDisplayMode
        _viewModel = StateObject(wrappedValue: StandardQuizViewModel(
            quizSet: initialSpecialQuizSet,
            course: nil,
            allSetsInCourse: initialAllSetsInCourse,
            timeLimit: initialTimeLimit,
            difficulty: initialDifficulty,
            selectedSkills: initialSelectedSkills,
            selectedGenres: initialSelectedGenres,
            mistakeTolerance: initialMistakeTolerance
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: backgroundColors)
            
            // 背景に非表示のNavigationLinkを配置して、プログラムによる遷移を可能にする
            backgroundNavigationLinks
            
            if viewModel.isQuizFinished {
                resultContent
            } else if viewModel.questions.isEmpty && viewModel.quizSet.setId == "REVIEW_MISTAKES" {
                // 復習問題がない場合の表示
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("復習する問題はありません！")
                        .font(.title2.bold())
                        .padding()
                    Text("素晴らしい！すべての問題をマスターしました。")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("ホームに戻る") {
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.bottom, 50)
                }
            } else {
                mainQuizView
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    isShowingExitAlert = true
                } label: {
                    Image(systemName: "pause.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // 達成度テストの場合のみ「準備画面に戻る」ボタンを表示
                if quizDisplayMode == .achievementTest {
                    Button {
                        dismiss() // 準備画面に戻る
                    } label: {
                        Label("準備画面に戻る", systemImage: "arrow.backward.circle.fill")
                            .font(.caption) // 小さめのフォント
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: viewModel.currentEngineViewModel?.question.id) { _ in
            viewModel.updateBookmarkStatus(bookmarkedIDs: Set(bookmarks.map { $0.questionID }))
        }
        .onAppear {
            viewModel.updateBookmarkStatus(bookmarkedIDs: Set(bookmarks.map { $0.questionID }))
            print("DEBUG: StandardQuizView onAppear - quizDisplayMode: \(quizDisplayMode)")
        }
        .onChange(of: viewModel.isQuizFinished) { isFinished in
            if isFinished {
                Task {
                    await handleQuizFinished()
                }
            }
        }
        
        .alert("中断しますか？", isPresented: $isShowingExitAlert) {
                Button("中断する", role: .destructive) {
                    dismiss() // 画面を閉じる
                }
                Button("続ける", role: .cancel) {
                    // 何もせずアラートを閉じるだけ
                }
            } message: {
                Text("現在のスコアと進捗は保存されません。")
            }
    }
    
    // MARK: - UI Sections
    
    @ViewBuilder
    private var backgroundNavigationLinks: some View {
        // 「次のセットへ」ボタンが押されたときの画面遷移
        if let nextSet = navigateToNextSet {
            // isLinkActive と同様の働きをする NavigationLink
            NavigationLink(
                destination: destinationForNextSet(nextSet),
                isActive: .constant(true),
                label: { EmptyView() }
            )
        }
        
        // 「間違えた問題を復習」が押されたときの画面遷移
        NavigationLink(
            destination: StandardQuizView(
                specialQuizSet: QuizSet(
                    setId: "REVIEW_MISTAKES",
                    setName: "間違えた問題の復習",
                    questions: viewModel.getIncorrectQuestions()
                ),
                timeLimit: viewModel.timePerQuestion
            ),
            isActive: $startReviewQuiz
        ) { EmptyView() }
    }
    
    @ViewBuilder
    private func destinationForNextSet(_ nextSet: QuizSet) -> some View {
        // viewModelがコース情報を持っているか確認
        if let course = viewModel.course, let allSets = viewModel.allSetsInCourse {
            // 通常のコースの場合
            QuizStartPromptView(quizSet: nextSet, course: course, allSetsInCourse: allSets)
        } else if let allSets = viewModel.allSetsInCourse {
            // 語彙クイズなどの場合
            QuizStartPromptView(specialQuizSet: nextSet, allSets: allSets)
        }
    }
    
    private var mainQuizView: some View {
        VStack(spacing: 0) {
            quizHeader // 新しいヘッダーに差し替え
                .padding(.horizontal)
            
            if let engineViewModel = viewModel.currentEngineViewModel {
                QuizEngineView(
                    viewModel: engineViewModel,
                    onSelectOption: { selectedIndex in
                        viewModel.selectAnswer(at: selectedIndex)
                    },
                    onNextQuestion: {
                        viewModel.submitCurrentAnswer() // 解答を確定
                        viewModel.nextQuestion() // 次の問題へ
                    },
                    onBookmark: {
                        Task {
                            await viewModel.toggleBookmark(context: modelContext)
                        }
                    },
                    isBookmarked: viewModel.isBookmarked,
                    shouldShowCorrectAnimation: viewModel.shouldShowCorrectAnimation,
                    isTimeAttackMode: !viewModel.shouldShowCorrectAnimation // shouldShowCorrectAnimationがfalseならtrue
                )
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(DesignSystem.Elements.cornerRadius)
        .padding()
    }
    
    @ViewBuilder
    private var resultContent: some View {
        if let resultData = resultViewModel.resultData {
            UnifiedResultView(
                resultData: resultData,
                isNewRecord: self.isNewRecord, // ←判定結果を渡すように変更
                onAction: { actionType in
                    handleResultAction(actionType)
                }
            )
        } else {
            // resultDataが生成されるまでの間、インジケータを表示
            ProgressView("結果を集計中...")
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleQuizFinished() async {
        // 1. 新しい結果を保存する前に、ハイスコアかどうかを判定する
        checkForNewRecord(currentScore: viewModel.score, quizSetId: viewModel.quizSet.setId)
        
        // 2. 新しい結果を保存する
        await viewModel.saveResult(context: modelContext)
        
        // 3. 結果データを生成する
        resultViewModel.generateResult(
            score: viewModel.score,
            totalQuestions: viewModel.questions.count,
            incorrectQuestions: viewModel.getIncorrectQuestions(),
            allQuestionsInQuiz: viewModel.questions,
            mode: quizDisplayMode == .achievementTest ? .achievementTest : .standard,
            nextQuizSet: findNextQuizSet(),
            difficulty: viewModel.difficulty,
            selectedSkills: viewModel.selectedSkills,
            selectedGenres: viewModel.selectedGenres,
            mistakeTolerance: viewModel.mistakeTolerance,
            timeLimit: viewModel.timePerQuestion,
            userSelectedAnswers: viewModel.userSelectedAnswers // 追加
        )
    }

    private func checkForNewRecord(currentScore: Int, quizSetId: String) {
        // このクイズセットの過去の結果だけを抜き出す
        let pastScoresForThisSet = allResults
            .filter { $0.setId == quizSetId }
            .map { $0.score }
        
        // 過去の最高点を取得（記録がなければ0点とする）
        let highScore = pastScoresForThisSet.max() ?? 0
        
        // 今回のスコアが過去の最高点より高いか判定
        if currentScore > highScore {
            self.isNewRecord = true
        } else {
            self.isNewRecord = false
        }
    }
    
    // ★ 新設: 押されたボタンに応じて処理を振り分けるメソッド
    private func handleResultAction(_ type: ResultActionType) {
        switch type {
        case .tryAgain:
            self.isNewRecord = false
            viewModel.restartQuiz()
        case .reviewMistakes:
            // 画面を閉じてから、次の画面に遷移するフラグを立てる
            dismiss()
            DispatchQueue.main.async {
                startReviewQuiz = true
            }
        case .nextSet:
            if let nextSet = findNextQuizSet() {
                navigateToNextSet = nextSet
            }
        case .backToCourse, .backToHome:
            AppNotificationManager.shared.checkForNewAchievements(context: modelContext)
            QuizCompletionNotifier.shared.quizDidComplete.send()
            dismiss()
        case .backToPreparation:
            dismiss() // 準備画面に戻る（現在のビューを閉じる）
        }
    }
    
    private func findNextQuizSet() -> QuizSet? {
        if let allSets = viewModel.allSetsInCourse {
            if let currentIndex = allSets.firstIndex(where: { $0.id == viewModel.quizSet.id }),
               currentIndex + 1 < allSets.count {
                return allSets[currentIndex + 1]
            }
        }
        return nil
    }
    
    /// クイズ画面の上部に表示するヘッダー
    @ViewBuilder
    private var quizHeader: some View {
        VStack(spacing: 4) {
            HStack {
                // コース名とセット名
                VStack(alignment: .leading, spacing: 2) {
                    if let courseName = viewModel.course?.courseName {
                        Text(courseName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(viewModel.quizSet.setName)
                        .font(.headline.bold())
                        .lineLimit(1)
                }
                
                Spacer()
                
                // タイマー
                if viewModel.timePerQuestion != SettingsManager.shared.timerOffValue {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("\(viewModel.remainingTime)")
                            .font(.body.monospacedDigit())
                    }
                    .foregroundColor(DesignSystem.Colors.brandPrimary)
                }
            }
            
            // プログレスバー
            HStack(spacing: 8) {
                ProgressView(value: viewModel.progress)
                    .tint(DesignSystem.Colors.brandPrimary)
                Text(viewModel.questionNumberText)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    
    @ViewBuilder
    private var focusHeader: some View {
        HStack(spacing: 16) {
            ProgressView(value: viewModel.progress)
                .tint(DesignSystem.Colors.brandPrimary)
            
            if viewModel.timePerQuestion != SettingsManager.shared.timerOffValue {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text("\(viewModel.remainingTime)")
                        .font(.body.monospacedDigit())
                }
                .foregroundColor(DesignSystem.Colors.brandPrimary)
            }
        }
        .padding(.vertical, 4)
    }
    
    
    private struct StandardResultView: View {
        let score: Int
        let totalQuestions: Int
        let incorrectQuestions: [Question]
        let onReview: () -> Void
        let onRestart: () -> Void
        let onDismiss: () -> Void
        let quizSetId: String?
        let course: Course?
        let nextQuizSet: QuizSet?
        let allSetsInCourse: [QuizSet]?
        @State private var shouldShowSurvey = false
        @State private var isSurveyDismissed = false
        
        private var accuracy: Double {
            totalQuestions > 0 ? Double(score) / Double(totalQuestions) : 0
        }
        
        private var feedback: (icon: String, title: String, message: String, color: Color) {
            if accuracy >= 0.9 { return ("sparkles", "素晴らしい！", "すごすぎます！この調子で頑張りましょう！", .yellow) }
            else if accuracy >= 0.7 { return ("hand.thumbsup.fill", "お見事！", "高い正答率です！間違えた問題を復習して完璧にしましょう。", .green) }
            else if accuracy >= 0.5 { return ("flame.fill", "ナイスチャレンジ！", "あと一歩です！間違えた問題を中心に復習するのがおすすめです。", .orange) }
            else { return ("book.fill", "お疲れ様でした", "大切なのはここからの復習です。一歩ずつ着実に進みましょう。", .blue) }
        }
        
        var body: some View {
            VStack(spacing: 15) {
                Spacer()
                Image(systemName: feedback.icon).font(.system(size: 60)).foregroundColor(feedback.color).padding(.bottom, 10)
                Text(feedback.title).font(.largeTitle.bold())
                Text("あなたのスコア").font(.headline).foregroundColor(.secondary)
                VStack {
                    Text("\(score) / \(totalQuestions)").font(.system(size: 60, weight: .bold))
                    Text(String(format: "正答率: %.1f%%", accuracy * 100)).font(.headline).foregroundColor(.secondary).padding(.top, -10)
                }
                Text(feedback.message).font(.body).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                Spacer()
                if shouldShowSurvey && !isSurveyDismissed, let quizSetId = quizSetId {
                    FeedbackSurveyView(quizSetId: quizSetId, onDismiss: { isSurveyDismissed = true }).padding(.bottom)
                }
                VStack(spacing: 12) {
                    if let nextSet = nextQuizSet, let course = course, let allSets = allSetsInCourse {
                        NavigationLink(destination: QuizStartPromptView(quizSet: nextSet, course: course, allSetsInCourse: allSets)) {
                            Label("次のセットに進む", systemImage: "arrow.right.circle.fill")
                                .font(DesignSystem.Fonts.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity)
                                .background(Color.accentColor).cornerRadius(DesignSystem.Elements.cornerRadius)
                        }
                    }
                    // Button(action: onReview) { Label("間違えた問題だけ復習 (\(incorrectQuestions.count)問)", systemImage: "arrow.counterclockwise.circle.fill") }.buttonStyle(SecondaryButtonStyle(color: .orange)).disabled(false)
                    Button(action: onRestart) { Text("もう一度挑戦する") }.buttonStyle(SecondaryButtonStyle(color: .green))
                    Button(action: onDismiss) { Text("ホームに戻る") }
                        .buttonStyle(SecondaryButtonStyle(color: DesignSystem.Colors.textSecondary))
                }
            }
            .padding(30)
            .onAppear {
                HapticManager.shared.playSuccess()
                if quizSetId != nil { self.shouldShowSurvey = FeedbackManager.shared.checkAndTriggerSurvey() }
            }
        }
    }
}
