import SwiftUI

/// タイムアタックの「準備画面」と「ゲーム画面」を管理するコンテナ
struct TimeAttackContainerView: View {
    
    // このコンテナの内部状態
    enum Phase {
        case loading
        case countdown
        case playing
    }
    
    // 前の画面から受け取る情報
    let selectedCourseIDs: Set<String>
    let mistakeLimit: Int
    
    // 状態管理プロパティ
    @State private var phase: Phase = .loading
    @State private var questions: [Question] = []
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss

    // UI表示用のState
    @State private var currentTip: String = ""
    @State private var progress: Double = 0.0
    @State private var statusText: String = "問題を準備しています..."
    @State private var countdownText: String = "3"
    @State private var hasStartedPreparation = false // 新しいフラグ
    @State private var isShowingExitAlert = false // 追加
    
    // タイマー
    @State private var tipTimer: Timer?
    @State private var progressTimer: Timer?
    @State private var countdownTimer: Timer?

    private let tips = [
        "Part 5はスピードが命！1問20秒以内を目指しましょう。",
        "選択肢を先に見て、文法の問題か語彙の問題か見極めよう。",
        "自信がない問題は、消去法で選択肢を絞るのが効果的です。"
    ]

    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            
            switch phase {
            case .loading:
                loadingContentView
            case .countdown:
                countdownView
            case .playing:
                TimeAttackView(questions: questions, mistakeLimit: mistakeLimit, selectedCourseIDs: selectedCourseIDs)
            }
        }
        .alert("エラー", isPresented: $showingErrorAlert, actions: {
            Button("OK") { dismiss() }
        }
               
               , message: {
            Text(errorMessage)
        })
        .alert("中断しますか？", isPresented: $isShowingExitAlert) { // 追加
            Button("中断する", role: .destructive) {
                dismiss()
            }
            Button("続ける", role: .cancel) {}
        } message: {
            Text("現在の進捗は保存されません。")
        }
        .task {
            // 問題の準備がまだ開始されていない場合にのみ実行
            if !hasStartedPreparation {
                hasStartedPreparation = true
                await prepareQuestions()
            }
        }
        .onAppear {
            setupTipTimer()
            startProgressSimulation()
        }
        .onDisappear {
            // この画面が非表示になるときに全てのタイマーを止める
            tipTimer?.invalidate()
            progressTimer?.invalidate()
            countdownTimer?.invalidate()
        }
        .navigationTitle("Part5タイムアタック")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Subviews for different phases
    
    private var loadingContentView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "square.stack.3d.down.right.fill")
                .font(.system(size: 80))
                .foregroundColor(DesignSystem.Colors.CourseAccent.purple)
                .symbolEffect(.bounce, value: progress)
            
            Text(statusText)
                .font(DesignSystem.Fonts.headline)
                .foregroundColor(.secondary)
                .padding(.top, 10)
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .padding(.horizontal, 50)
            
            Text(currentTip)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(height: 60)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    private var countdownView: some View {
        Text(countdownText)
            .font(.system(size: 70, weight: .bold, design: .rounded))
            .foregroundColor(.white) // 文字色を白に変更
            .padding(.horizontal, 30) // 横方向のパディング
            .padding(.vertical, 15) // 縦方向のパディング
            .background(Circle().fill(Color.black.opacity(0.4))) // 半透明の黒い円形背景
            .transition(.opacity.combined(with: .scale))
            .id(countdownText) // idを変更することで毎回アニメーションがトリガーされる
    }
    
    // MARK: - Logic Functions
    
    private func prepareQuestions() async {
        // ロードフェーズでない場合は何もしない
        guard phase == .loading else { return }

        do {
            let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
            let selectedCourses = allCourses.filter { selectedCourseIDs.contains($0.id) }
            let flattenedQuestions = selectedCourses
                .flatMap { $0.quizSets.flatMap { $0.questions } }
                .shuffled()
            
            guard !flattenedQuestions.isEmpty else {
                self.errorMessage = "選択されたコースに、利用可能な問題がありませんでした。"
                self.showingErrorAlert = true
                return
            }
            
            self.questions = flattenedQuestions
            // 読み込みが終わったら、カウントダウンを開始する
            self.startCountdown()
            
        } catch {
            self.errorMessage = "問題の読み込みに失敗しました。\n詳細: \(error.localizedDescription)"
            self.showingErrorAlert = true
        }
    }
    
    private func startCountdown() {
        // すでにカウントダウンフェーズであれば何もしない
        guard phase != .countdown else { return }

        // プログレスバーを100%にする
        withAnimation { progress = 1.0 }
        progressTimer?.invalidate()
        tipTimer?.invalidate()
        
        // カウントダウン状態に移行
        withAnimation {
            self.phase = .countdown
        }
        
        // 1秒ごとに数字を更新するタイマー
        var count = 3
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if count > 1 {
                count -= 1
                withAnimation {
                    self.countdownText = String(count)
                }
            } else {
                // "START!"を表示して、ゲーム画面に遷移
                countdownTimer?.invalidate()
                withAnimation {
                    self.countdownText = "START!"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.phase = .playing
                    }
                }
            }
        }
    }
    
    private func setupTipTimer() {
        currentTip = tips.randomElement() ?? ""
        tipTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { _ in
            withAnimation(.easeInOut) {
                currentTip = tips.randomElement() ?? ""
            }
        }
    }
    
    private func startProgressSimulation() {
        let simulationDuration = 2.5
        let increment = 0.01
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: simulationDuration * increment, repeats: true) { _ in
            if progress < 1.0 {
                progress = min(progress + increment, 1.0)
            } else {
                progressTimer?.invalidate()
            }
        }
    }
}
