import SwiftUI

/// タイムアタックモード専用のコンテナView
struct TimeAttackView: View {
    @StateObject private var viewModel: TimeAttackViewModel
    @State private var isShowingExitAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(questions: [Question], mistakeLimit: Int, selectedCourseIDs: Set<String>) {
        _viewModel = StateObject(wrappedValue: TimeAttackViewModel(
            questions: questions,
            mistakeLimit: mistakeLimit,
            selectedCourseIDs: selectedCourseIDs
        ))
    }


    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            
            // クイズ終了後は結果画面を表示
            if viewModel.isQuizFinished {
                TimeAttackReviewResultView(
                    score: viewModel.score,
                    attemptedCount: viewModel.attemptedCount,
                    mistakeLimit: viewModel.mistakeLimit,
                    incorrectQuestions: viewModel.incorrectQuestions,
                    questions: viewModel.originalQuestions,
                    userAnswers: viewModel.answeredQuestions,
                    onDismiss: { dismiss() },
                    averageAnswerTime: viewModel.averageAnswerTime,
                    incorrectCategoryCounts: viewModel.incorrectCategoryCounts,
                    selectedCourseIDs: viewModel.selectedCourseIDs
                )
            } else {
                // クイズ中の画面
                mainQuizView
            }
        }
        .alert("中断しますか？", isPresented: $isShowingExitAlert) {
                    Button("中断する", role: .destructive) {
                        // 「中断する」が押されたら、元の画面に戻る処理を実行
                        dismiss()
                    }
                    Button("続ける", role: .cancel) {
                        // 何も処理しない（アラートが閉じるだけ）
                    }
                } message: {
                    Text("現在のスコアと進捗は保存されません。")
                }
        .navigationTitle("タイムアタック")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { isShowingExitAlert = true }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            // TimeAttackContainerViewでカウントダウンが終わってから遷移してくるので、
            // ここでは直接ゲームを開始する
            viewModel.startGame()
        }
        .toolbar(.hidden, for: .tabBar) // タブバーを非表示にする
    }
    
    private var mainQuizView: some View {
        VStack(spacing: 20) {
            // タイムアタック専用ヘッダー
            TimeAttackHeader(
                remainingTime: viewModel.timeAttackRemainingTime,
                mistakeCount: viewModel.incorrectCount,
                mistakeLimit: viewModel.mistakeLimit,
                correctCount: viewModel.score,
                totalQuestionsCount: viewModel.totalQuestionsCount // 追加
            )

            // QuizEngineViewを呼び出し
            if let engineViewModel = viewModel.currentEngineViewModel {
                QuizEngineView(
                    viewModel: engineViewModel,
                    onSelectOption: { index in
                        viewModel.selectOption(at: index)
                    },
                    onNextQuestion: {},
                    isTimeAttackMode: true
                )
            } else {
                ProgressView()
            }
        }
        .padding()
    }
}


// MARK: - Reusable Nested UI Components

/// タイムアタック用のヘッダーUI
private struct TimeAttackHeader: View {
    let remainingTime: Int
    let mistakeCount: Int
    let mistakeLimit: Int
    let correctCount: Int
    let totalQuestionsCount: Int
    
    // タイマーバーの進捗を計算
    private var timeProgress: Double {
        let totalDuration = 300.0 // 5分 = 300秒
        return Double(remainingTime) / totalDuration
    }
    
    // タイマーバーの色を決定
    private var timeProgressColor: Color {
        if timeProgress > 0.6 { return .green }
        if timeProgress > 0.3 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "stopwatch.fill")
                    Text(String(format: "%02d:%02d", remainingTime / 60, remainingTime % 60))
                }
                .font(.headline.monospacedDigit()).foregroundColor(.purple)
                
                Spacer()
                
                // 正解数と全問題数を表示
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("\(correctCount) / \(totalQuestionsCount)")
                }
                .font(.headline.monospacedDigit()).foregroundColor(.green)
                
                Spacer()
                
                if mistakeLimit > 0 {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill") // ハートアイコンに変更
                            .foregroundColor(.red)
                        Text("\(mistakeLimit - mistakeCount)") // 残りミス回数を表示
                        Text("/ \(mistakeLimit)") // 総ミス許容回数を表示
                    }
                    .font(.headline.monospacedDigit())
                }
            }
            .padding(.horizontal)
            
            // タイマーバー
            ProgressView(value: timeProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: timeProgressColor))
                .animation(.linear, value: timeProgress) // スムーズなアニメーション
                .frame(height: 8) // バーの高さ
                .cornerRadius(4) // 角を丸くする
                .padding(.horizontal) // 左右のパディング
        }
    }
}


// 元々QuizViewにあったTimeAttack用の結果表示Viewをこちらに移動
private struct TimeAttackReviewResultView: View {
    let score: Int
    let attemptedCount: Int
    let mistakeLimit: Int
    let incorrectQuestions: [Question]
    let questions: [Question]
    let userAnswers: [String: Int]
    let onDismiss: () -> Void
    let averageAnswerTime: Double
    let incorrectCategoryCounts: [String: Int]
    let selectedCourseIDs: Set<String> // 追加
    
    @State private var selectedCourseNames: [String] = []
    
    private var attemptedQuestions: [Question] {
        questions.filter { userAnswers.keys.contains($0.id) }
    }
    
    private var accuracy: Double {
        guard attemptedCount > 0 else { return 0.0 }
        return Double(score) / Double(attemptedCount)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // 1. スコア表示の強化
                VStack(spacing: 10) {
                    Text("タイムアップ！")
                        .font(.largeTitle.bold())
                        .foregroundColor(.red)
                    
                    Text("あなたのスコア")
                        .font(.title2)
                    
                    Text("\(score) / \(attemptedCount)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(accuracy > 0.7 ? .green : .orange)
                    
                    Text("正答率: \(Int(accuracy * 100))%")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if mistakeLimit != 0 && incorrectQuestions.count >= mistakeLimit {
                        Text("ミス許容回数に達しました。")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }
                .padding(.bottom, 20)
                
                // 2. パフォーマンスのサマリー
                VStack(alignment: .leading, spacing: 15) {
                    Text("パフォーマンス分析")
                        .font(.title2.bold())
                    
                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundColor(.blue)
                        Text("平均解答時間:")
                        Spacer()
                        Text("\(String(format: "%.1f", averageAnswerTime))秒/問")
                            .font(.headline)
                    }
                    
                    if !incorrectCategoryCounts.isEmpty {
                        VStack(alignment: .leading) {
                            Text("苦手分野:")
                            ForEach(incorrectCategoryCounts.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                                HStack {
                                    Image(systemName: "xmark.octagon.fill")
                                        .foregroundColor(.red)
                                    Text("\(category): \(count)問")
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // 3. クイズ設定の表示
                VStack(alignment: .leading, spacing: 10) {
                    Text("クイズ設定")
                        .font(.title2.bold())
                    
                    HStack {
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.brown)
                        Text("出題範囲:")
                        Spacer()
                        Text(selectedCourseNames.joined(separator: ", "))
                            .font(.headline)
                    }
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("ミス許容回数:")
                        Spacer()
                        Text(mistakeLimit == 0 ? "上限なし" : "\(mistakeLimit) 回")
                            .font(.headline)
                    }
                    
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.purple)
                        Text("時間制限:")
                        Spacer()
                        Text("5分")
                            .font(.headline)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // 4. 次のアクションへの明確な誘導
                VStack(spacing: 15) {
                    Button(action: { /* 間違えた問題の復習ロジック */ }) {
                        Label("間違えた問題を復習する", systemImage: "arrow.counterclockwise.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button(action: { /* もう一度挑戦するロジック */ }) {
                        Label("もう一度挑戦する", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button(action: onDismiss) {
                        Text("ホームに戻る")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal)
                
                List {
                    Section(header: Text("解答のレビュー")) {
                        ForEach(attemptedQuestions) { question in
                            let userAnswerIndex = userAnswers[question.id]
                            let isCorrect = userAnswerIndex == question.correctAnswerIndex
                            
                            HStack {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrect ? .green : .red)
                                VStack(alignment: .leading) {
                                    Text(question.questionText)
                                        .font(.caption.bold())
                                        .lineLimit(1)
                                    if let userAnswerIndex = userAnswerIndex {
                                        Text("あなたの解答: \(question.options[userAnswerIndex])")
                                            .font(.caption2)
                                    }
                                    if !isCorrect {
                                        Text("正解: \(question.options[question.correctAnswerIndex])")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 300) // リストの高さを固定
            }
            .padding(.vertical)
        }
        .onAppear {
            Task {
                await loadCourseNames()
            }
        }
    }
    
    private func loadCourseNames() async {
        do {
            let allCourses = try await DataService.shared.loadCourseManifest()
            self.selectedCourseNames = allCourses.filter { selectedCourseIDs.contains($0.id) }.map { $0.courseName }
        } catch {
            print("Failed to load course names: \(error)")
        }
    }
}

