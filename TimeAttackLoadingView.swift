import SwiftUI

struct TimeAttackLoadingView: View {
    // MARK: - Properties
    let selectedCourseIDs: Set<String>
    let mistakeLimit: Int
    // ★ 変更: goBackAction を削除し、navigationManager を受け取る
    let navigationManager: TimeAttackNavigationManager
    
    @State private var allQuestions: [Question] = []
    @State private var isReadyToStart: Bool = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    @State private var currentTip: String = ""
    @State private var tipTimer: Timer?
    @State private var progress: Double = 0.0
    @State private var progressTimer: Timer?
    @State private var statusText: String = "問題を準備しています..."
    @State private var isLoadingComplete: Bool = false
    @State private var countdown: Int = 3
    @State private var countdownTimer: Timer?

    private let tips = [
        "Part 5はスピードが命！1問20秒以内を目指しましょう。",
        "選択肢を先に見て、文法の問題か語彙の問題か見極めよう。",
        "自信がない問題は、消去法で選択肢を絞るのが効果的です。",
        "主語(S)と動詞(V)を素早く見つけるのが、正解への近道。",
        "文の構造が複雑なときは、接続詞や関係詞に注目。",
        "最高の脳トレをお届けします！準備中...",
        "全神経を集中させて、自己ベストを目指せ！"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if !isLoadingComplete {
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

            } else {
                Text(statusText)
                    .font(.system(size: 90, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.CourseAccent.purple)
                    .scaleEffect(2.0)
                    .transition(.opacity.combined(with: .scale))
            }
            
            Spacer()

            NavigationLink(
                destination: TimeAttackView(
                    questions: allQuestions,
                    mistakeLimit: mistakeLimit,
                    selectedCourseIDs: selectedCourseIDs
                ),
                isActive: $isReadyToStart
            ) {
                EmptyView()
            }
        }
        .onChange(of: isReadyToStart) {
            // isReadyToStartがtrueからfalseに戻った時（＝TimeAttackViewが閉じられた時）を検知
            if !isReadyToStart {
                // 大元の設定画面まで戻るようにナビゲーションをOFFにする
                navigationManager.isLinkActive = false
            }
        }
        .navigationTitle("準備中")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await prepareQuestions()
        }
        .onAppear {
            setupTipTimer()
            startProgressSimulation()
        }
        .onDisappear {
            tipTimer?.invalidate()
            progressTimer?.invalidate()
            countdownTimer?.invalidate()
        }
        .alert("エラー", isPresented: $showingErrorAlert, actions: {
            Button("OK") { dismiss() }
        }, message: {
            Text(errorMessage)
        })
    }
    
    // MARK: - Private Methods
    
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
    
    private func startCountdown() {
        withAnimation { progress = 1.0 }
        progressTimer?.invalidate()
        
        withAnimation {
            self.isLoadingComplete = true
            self.statusText = String(countdown)
        }
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
                withAnimation {
                    self.statusText = String(countdown)
                }
            } else {
                countdownTimer?.invalidate()
                withAnimation {
                    self.statusText = "START!"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isReadyToStart = true
                }
            }
        }
    }
    
    private func prepareQuestions() async {
        do {
            let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
            let selectedCourses = allCourses.filter { selectedCourseIDs.contains($0.id) }
            let flattenedQuestions = selectedCourses
                .flatMap { $0.quizSets.flatMap { $0.questions } }
                .shuffled()
            
            guard !flattenedQuestions.isEmpty else {
                self.errorMessage = "選択されたコースに、利用可能な問題がありませんでした。コースの選択を変えて再度お試しください。"
                self.showingErrorAlert = true
                return
            }
            self.allQuestions = flattenedQuestions
            startCountdown()
            
        } catch {
            self.errorMessage = "問題の読み込みに失敗しました。通信環境の良い場所で再度お試しください。\n\n詳細: \(error.localizedDescription)"
            self.showingErrorAlert = true
        }
    }
}
