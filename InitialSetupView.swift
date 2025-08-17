import SwiftUI
import SwiftData

// MARK: - State Management

/// 新しいオンボーディングフローのステップを定義
private enum OnboardingStep {
    case diagnosticPrompt
    case diagnosticTest
    case analysisResult
    case notificationPermissionPrompt
    case goalSetting
}

// MARK: - Main View

/// 新しいオンボーディングフロー全体を管理するコンテナView
struct InitialSetupView: View {
    
    @Environment(\.dismiss) private var dismiss // 追加
    @State private var currentStep: OnboardingStep = .diagnosticPrompt // ★★★ 初期ステップを変更 ★★★
    
    // アンケートの回答を保持するState
    @State private var targetScore: String = SettingsManager.shared.targetScore
    @State private var biggestChallenge: String = ""
    
    // 分析されたおすすめコースを保持するState
    @State private var recommendedCourseForSetup: Course?
    
    /// このフローが全て完了したときに呼ばれるアクション
    var onComplete: () -> Void

    var body: some View {
        // 現在のステップに応じて表示するViewを切り替える
        switch currentStep {
        case .diagnosticPrompt:
            NewDiagnosticPromptView(
                targetScore: targetScore,
                onStart: {
                    withAnimation { self.currentStep = .diagnosticTest }
                }
            )
        case .diagnosticTest:
            SetupDiagnosticWrapperView(
                targetScore: targetScore, // ユーザーレベルを渡す
                onTestComplete: { course in
                    self.recommendedCourseForSetup = course
                    SettingsManager.shared.hasTakenDiagnosticTest = true
                    withAnimation { self.currentStep = .analysisResult }
                }
            )
        case .analysisResult:
            NewAnalysisResultView(
                recommendedCourse: recommendedCourseForSetup,
                onProceed: {
                    withAnimation { self.currentStep = .notificationPermissionPrompt } // ★★★ 遷移先を変更 ★★★
                }
            )
        case .notificationPermissionPrompt: // ★★★ 追加 ★★★
            NotificationPermissionPromptView(onProceed: {
                withAnimation { self.currentStep = .goalSetting }
            })
        case .goalSetting:
            GoalSettingView(onComplete: {
                // GoalSettingViewが完了したら、InitialSetupViewを閉じる
                onComplete()
                // dismiss() // REMOVED: InitialSetupViewはNavigationView内で表示されるため、dismissは不要
            })
        }
    }
}

// MARK: - Subviews for Onboarding Flow

/// 実力診断テストの実施と完了を管理するためのラッパーView
private struct SetupDiagnosticWrapperView: View {
    let targetScore: String
    var onTestComplete: (Course?) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var showQuiz = false
    @State private var diagnosticQuizSet: QuizSet?
    @State private var isLoading = true

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("診断テストを準備中...")
            } else {
                // 準備が完了したら自動的にクイズ画面を表示
                Color.clear
            }
        }
        .task {
            await prepareDiagnosticTest()
            isLoading = false
            showQuiz = true // 準備完了後、自動でクイズ開始
        }
        .fullScreenCover(isPresented: $showQuiz) {
            // クイズ完了後の処理
            Task {
                let course = await RecommendationManager.generateRecommendation(context: self.modelContext)
                SettingsManager.shared.recommendedCourseId = course?.id
                onTestComplete(course)
            }
        } content: {
            if let quizSet = diagnosticQuizSet {
                NavigationView { StandardQuizView(specialQuizSet: quizSet, timeLimit: SettingsManager.shared.timerDuration) }
            } else {
                // ローディング中の表示（基本的にはtask内で処理が終わるはず）
                ProgressView()
            }
        }
    }
    
    private func prepareDiagnosticTest() async {
        // ユーザーのレベルに応じて問題数を5〜10問に調整
        let questionCount: Int
        switch targetScore {
        case "初めて挑戦 / 500点目標":
            questionCount = 5
        case "600点〜700点台を目指したい":
            questionCount = 8
        case "800点以上のハイスコアを狙う":
            questionCount = 10
        default:
            questionCount = 7 // デフォルト
        }
        
        let allCourses = try? await DataService.shared.loadAllCoursesWithDetails()
        let allQuestions = allCourses?.flatMap { $0.quizSets.flatMap { $0.questions } }.shuffled() ?? []
        let testQuestions = Array(allQuestions.prefix(questionCount))
        
        guard !testQuestions.isEmpty else { return }
        self.diagnosticQuizSet = QuizSet(setId: "DIAGNOSTIC_TEST", setName: "実力診断テスト", questions: testQuestions)
    }
}

/// 分析結果の表示View
private struct NewAnalysisResultView: View {
    let recommendedCourse: Course?
    var onProceed: () -> Void
    
    @State private var selectedGoalInMinutes: Int // 目標時間
    @State private var showPicker = false // ピッカーの表示/非表示
    
    // 選択可能な目標時間（分単位）
    private let cardOptions: [(minutes: Int, description: String)] = [
        (10, "通勤・通学中にサクッと"),
        (20, "毎日コツコツ"),
        (30, "集中して取り組む"),
        (45, "本気でスコアアップ"),
        (60, "がっつり学習"),
    ]
    
    private let pickerOptions: [Int] = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 90, 120]
    
    init(recommendedCourse: Course?, onProceed: @escaping () -> Void) {
        self.recommendedCourse = recommendedCourse
        self.onProceed = onProceed
        _selectedGoalInMinutes = State(initialValue: Int(SettingsManager.shared.dailyGoal / 60))
    }

    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: [DesignSystem.Colors.brandPrimary.opacity(0.3), .blue.opacity(0.3)])
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("分析が完了しました")
                        .font(.largeTitle.bold())
                    
                    if let course = recommendedCourse {
                        VStack {
                            Text("あなたの弱点は")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("『\(course.courseName)』のようです。")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(course.courseColor)
                            Text("まずはこのコースから始めるのがおすすめです！")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        
                        Text("この結果に基づき、あなた専用の学習プランを作成しました。")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                    } else {
                        Text("素晴らしい！特に苦手な分野は見つかりませんでした。")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // ★★★ 目標設定UIを統合 ★★★
                    VStack(spacing: 20) {
                        Text("最後に、毎日の学習目標を決めましょう！")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // カード形式の選択肢
                        VStack(spacing: 15) {
                            ForEach(cardOptions, id: \.minutes) { option in
                                Button(action: {
                                    selectedGoalInMinutes = option.minutes
                                    showPicker = false
                                }) {
                                    HStack {
                                        Text("\(option.minutes) 分")
                                            .font(.title2.bold())
                                        Spacer()
                                        Text(option.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(nil)
                                    }
                                    .padding()
                                    .background(selectedGoalInMinutes == option.minutes ? DesignSystem.Colors.brandPrimary.opacity(0.2) : DesignSystem.Colors.surfacePrimary)
                                    .cornerRadius(DesignSystem.Elements.cornerRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Elements.cornerRadius)
                                            .stroke(selectedGoalInMinutes == option.minutes ? DesignSystem.Colors.brandPrimary : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // その他の時間ボタン
                            Button(action: {
                                showPicker.toggle()
                            }) {
                                HStack {
                                    Text("その他の時間")
                                        .font(.title2.bold())
                                    Spacer()
                                    Image(systemName: showPicker ? "chevron.up" : "chevron.down")
                                }
                                .padding()
                                .background(showPicker ? DesignSystem.Colors.brandPrimary.opacity(0.2) : DesignSystem.Colors.surfacePrimary)
                                .cornerRadius(DesignSystem.Elements.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Elements.cornerRadius)
                                        .stroke(showPicker ? DesignSystem.Colors.brandPrimary : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        
                        // ピッカー
                        if showPicker {
                            Picker("目標時間", selection: $selectedGoalInMinutes) {
                                ForEach(pickerOptions, id: \.self) {
                                    Text("\($0) 分").tag($0)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 150)
                            .clipped()
                        }
                        
                        // 選択によるフィードバック
                        Text("毎日\(selectedGoalInMinutes)分続ければ、1ヶ月で約\(selectedGoalInMinutes * 30)分、\(String(format: "%.1f", Double(selectedGoalInMinutes * 30) / 60.0))時間の学習になります！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 500)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button("学習を始める！") {
                        saveAndProceed()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(30)
                .background(.ultraThinMaterial)
                .cornerRadius(DesignSystem.Elements.cornerRadius)
                .padding()
            }
        }
    }
    
    private func saveAndProceed() {
        let newGoalInSeconds = TimeInterval(selectedGoalInMinutes * 60)
        SettingsManager.shared.dailyGoal = newGoalInSeconds
        onProceed()
    }
}

/// 実力診断をスキップした場合に表示するView
private struct NewDiagnosticSkippedView: View {
    var onProceed: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "hand.point.right.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            Text("承知しました")
                .font(.largeTitle.bold())
            Text("診断テストはいつでもマイページから受けられます.\nまずは一般的な学習プランから始めましょう。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button("目標設定に進む", action: onProceed)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(30)
    }
}
