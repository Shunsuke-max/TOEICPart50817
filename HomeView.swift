import SwiftUI
import SwiftData
import Charts


struct DailyStudyRecord: Identifiable {
    let id: String
    let date: Date
    var studyTime: TimeInterval
}

extension TimeInterval {
    /// 時間と分 (HH:mm) の形式にフォーマットする
    func toHourMinuteFormat() -> String {
        let time = Int(self)
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    /// 時間と分（X時間Y分）の形式にフォーマットする
    func toHourMinuteJapaneseFormat() -> String {
        if self <= 0 { return "0分" }
        let time = Int(self)
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)時間\(minutes)分"
        } else if hours > 0 {
            return "\(hours)時間"
        } else {
            return "\(minutes)分"
        }
    }
}

struct HomeView: View {
    @Binding var selectedTab: Tab
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    
    // Viewの頭脳となるViewModelを@StateObjectとして生成
    @StateObject private var viewModel = HomeViewModel()
    
    // SwiftDataのデータ取得はViewで行う
    @Query private var quizResults: [QuizResult]
    
    // UIの表示状態のみを管理するState
    @State private var isShowingSettings = false
    @State private var isShowingGoalSetting = false
    @State private var selectedCourseIDForRecommendation: String?
    @State private var isStarAnimating = false
    @State private var showScoreInfoAlert = false // ★★★ スコア目安の注釈アラート用 ★★★
    @Namespace private var homeNamespace
    @State private var showPaywall = false
    
    // ★★★ グラフのツールチップ用 State ★★★
    @State private var selectedChartRecord: DailyStudyRecord?
    @State private var chartTooltipPosition: CGPoint?
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            AuroraBackgroundView(colors: [
                DesignSystem.Colors.brandPrimary,
                DesignSystem.Colors.CourseAccent.yellow
            ])
            
            ScrollView {
                VStack(spacing: 32) { // Spacing increased for more separation
                    
                    // ★★★ 統合された新しいダッシュボードカードを一番上に配置 ★★★
                    mainDashboardCard
                    
                    if !SettingsManager.shared.hasTakenDiagnosticTest {
                        diagnosticTestCard
                    }
                    
                    
                    
                    weeklyBarChartCard
                    
                    if let course = viewModel.recommendedCourse, !SettingsManager.shared.hasSeenInitialRecommendation {
                        recommendationCard(for: course)
                    }
                    
                    if !SettingsManager.shared.isPremiumUser {
                        upgradeBanner
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.top) // mainDashboardCardが一番上に来るので、paddingをVStackに追加
            }
            
            // --- 広告バナー ---
            if !SettingsManager.shared.isPremiumUser {
                BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2934735716")
                    .frame(height: 50)
                    .background(Color(.systemBackground).ignoresSafeArea(.all, edges: .bottom))
            }
        }
        .navigationTitle("ホーム")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { isShowingSettings = true }) { // ハンバーガーメニューで設定を開く
                    Image(systemName: "line.3.horizontal").foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                // 通知アイコンは削除
            }
        }
        .fullScreenCover(isPresented: $viewModel.showMilestoneView) {
            if let milestone = viewModel.achievedMilestone {
                MilestoneUnlockedView(days: milestone.days, message: milestone.message) {
                    viewModel.showMilestoneView = false
                }
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.showMilestoneView)
        .fullScreenCover(isPresented: $viewModel.showGoalAchievedView) {
            GoalAchievedView(goalTimeMinutes: Int(viewModel.dailyGoal / 60)) {
                viewModel.showGoalAchievedView = false
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.showGoalAchievedView)
        .sheet(isPresented: $isShowingSettings) { SettingsView() }
        .sheet(isPresented: $isShowingGoalSetting) { GoalSettingView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        // ★★★ 注釈アラートのメッセージを修正 ★★★
        .alert("スコアの目安について", isPresented: $showScoreInfoAlert) {
            Button("OK") {}
        } message: {
            Text("TOEICリーディングセクション(495点)のうち、Part5で獲得が期待される点数です。")
        }
        .onAppear {
            SoundManager.shared.playBGM(named: "embrace-364091.mp3")
            Task {
                // ViewModelにModelContextを渡して初期設定
                viewModel.setup(context: modelContext)
                // データを更新
                await viewModel.updateAllStats(quizResults: quizResults)
                // await viewModel.loadDailyQuizData() // コメントアウト
                await viewModel.fetchRecommendation()
            }
        }
        .onDisappear {
            SoundManager.shared.stopBGM()
        }
        // quizResultsが変化したらViewModelのメソッドを呼んで再計算
        .onChange(of: quizResults) {
            Task {
                await viewModel.updateAllStats(quizResults: quizResults)
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var diagnosticTestCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(DesignSystem.Colors.brandPrimary)
                Text("実力診断テスト")
                    .font(DesignSystem.Fonts.title)
                Spacer()
            }
            
            Text("まずはあなたの実力をチェック！最適な学習プランをご提案します。")
                .font(.body)
                .foregroundColor(.secondary)
            
            NavigationLink(destination: InitialSetupView(onComplete: {
                Task {
                    // HomeViewに戻ってきたときにViewModelを更新
                    await viewModel.updateAllStats(quizResults: quizResults)
                    await viewModel.fetchRecommendation()
                }
                return
            })) {
                Text("テストを受ける")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(DesignSystem.Colors.brandPrimary.gradient)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var mainDashboardCard: some View {
        VStack(spacing: 24) { // 間隔を調整
            
            // --- 1. 予測スコア & プログレスバー ---
            VStack(spacing: 8) {
                HStack(alignment: .center) { // 中央揃えに変更
                    VStack(alignment: .leading, spacing: 2) {
                        Text("予測スコア")
                            .font(.headline.bold())
                            .foregroundColor(.white.opacity(0.9))
                        
                        // ★ 満点併記に変更
                        Text("\(viewModel.predictedPart5Score) / 150点")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: { showScoreInfoAlert = true }) {
                        Image(systemName: "info.circle")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.leading, -4) // アイコンをスコアに近づける
                    
                    Spacer()
                    
                    Button(action: { isShowingGoalSetting = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("目標変更")
                        }
                        .font(.caption.bold())
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                
                GeometryReader { geometry in
                    // ★★★ if-else文に修正してエラーを解消 ★★★
                    if geometry.size.width.isFinite && geometry.size.width > 0 {
                        let progress = max(0, min(Double(viewModel.predictedPart5Score - 20) / 130.0, 1.0))
                        let starSize: CGFloat = 20
                        let starPositionX = (geometry.size.width - starSize) * progress
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.2))
                                .frame(height: 16)
                            
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "FEE2B3"), DesignSystem.Colors.CourseAccent.yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geometry.size.width * progress, height: 16)
                            
                            Image(systemName: "star.fill")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(4)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "E8A200")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .white.opacity(0.4), radius: 1, x: 0, y: 1)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .frame(width: starSize, height: starSize)
                                .offset(x: starPositionX)
                        }
                        .frame(height: starSize)
                    } else {
                        // 幅が確定するまでプレースホルダーを表示
                        Capsule().fill(Color.black.opacity(0.2)).frame(height: 16)
                    }
                }
                .frame(height: 20)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.predictedPart5Score)
            
            // --- 2. 今日の学習目標 (円グラフ) ---
            dailyProgressCircleView
                .frame(height: 180)
            
            // --- 3. 学習開始ボタン ---
            Button(action: {
                selectedTab = .training
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("学習を開始する")
                }
                .font(.headline.bold())
                .foregroundColor(DesignSystem.Colors.brandPrimary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
            }
            
            // --- 4. 連続学習 & 総学習時間 ---
            Divider().background(Color.white.opacity(0.5))
            
            HStack {
                Spacer()
                VStack {
                    Text("連続学習").font(.caption).foregroundColor(.white.opacity(0.8))
                    if viewModel.streakCount > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(viewModel.streakCount)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text("日")
                                .font(.headline)
                        }
                        Text("自己ベスト: \(viewModel.longestStreakCount)日")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("今日からスタート！")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                }
                .animation(.default, value: viewModel.streakCount)
                .sensoryFeedback(.increase, trigger: viewModel.streakCount)
                Spacer()
                Divider().frame(height: 40).background(Color.white.opacity(0.3))
                Spacer()
                VStack {
                    Text("総学習時間").font(.caption).foregroundColor(.white.opacity(0.8))
                    Text(viewModel.totalStudyTime.toHourMinuteFormat()).font(.system(size: 28, weight: .bold, design: .rounded))
                }
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [DesignSystem.Colors.brandPrimary.opacity(0.9), DesignSystem.Colors.brandPrimary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    
    
    
    
    private var upgradeBanner: some View {
        Button(action: {
            showPaywall = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("全ての機能を使い放題").font(.headline.bold())
                    Text("広告非表示・模試受け放題など").font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.white)
            .padding(16)
            .background(DesignSystem.Colors.brandPrimary.gradient)
            .cornerRadius(16)
        }
    }
    
    // ★★★ 【改善】インタラクティブな週次活動グラフ ★★★
    private var weeklyBarChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("今週の活動")
                    .font(DesignSystem.Fonts.title)
                Spacer()
                let weeklyTotal = viewModel.weeklyDailyRecords.reduce(0) { $0 + $1.studyTime }
                Text("合計: \(weeklyTotal.toHourMinuteJapaneseFormat())")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
            }
            .padding([.top, .horizontal])
            
            if viewModel.weeklyDailyRecords.isEmpty || viewModel.weeklyDailyRecords.allSatisfy({ $0.studyTime == 0 }) {
                Spacer()
                Text("最初の学習を記録しよう！")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 100) // Give some height to center the text
                Spacer()
            } else {
                Chart(viewModel.weeklyDailyRecords) { record in
                    BarMark(
                        x: .value("曜日", record.id),
                        y: .value("学習時間(分)", record.studyTime / 60)
                    )
                    .foregroundStyle(DesignSystem.Colors.brandPrimary.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel().font(.caption2)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom)
                // ★★★ グラフのインタラクションを追加 ★★★
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                    .onChanged { value in
                                        let location = value.location
                                        // Find the closest bar to the tap location
                                        if let (date, _) = proxy.value(at: location, as: (String, Double).self) {
                                            if let record = viewModel.weeklyDailyRecords.first(where: { $0.id == date }) {
                                                self.selectedChartRecord = record
                                                self.chartTooltipPosition = location
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        // Hide tooltip when drag ends
                                        self.selectedChartRecord = nil
                                        self.chartTooltipPosition = nil
                                    }
                            )
                    }
                }
                .overlay {
                    // ★★★ ツールチップの表示 ★★★
                    if let record = selectedChartRecord, let position = chartTooltipPosition {
                        VStack(alignment: .center, spacing: 2) {
                            Text(record.id)
                                .font(.caption.bold()).foregroundColor(.primary)
                            Text(record.studyTime.toHourMinuteJapaneseFormat())
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(.regularMaterial)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .position(x: position.x, y: position.y - 30) // 指の少し上に表示
                        .transition(.opacity.animation(.easeInOut))
                        .allowsHitTesting(false) // Prevent tooltip from blocking gestures
                    }
                }
            }
        }
        .frame(height: 180)
        .background(.regularMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func recommendationCard(for course: Course) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("あなたへのおすすめ")
                    .font(DesignSystem.Fonts.title)
                Spacer()
            }
            
            Text("実力診断の結果、**「\(course.courseName)」**の学習から始めるのがおすすめです！")
                .font(.body)
                .foregroundColor(.secondary)
            
            NavigationLink(destination: QuizSetSelectionView(course: course)) {
                Text("早速はじめる")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(course.courseColor.gradient)
                    .cornerRadius(10)
            }
            .simultaneousGesture(TapGesture().onEnded {
                SettingsManager.shared.hasSeenInitialRecommendation = true
            })
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    
    
    @ViewBuilder
    private var dailyProgressCircleView: some View {
        let progress = viewModel.dailyGoal > 0 ? min(viewModel.todaysProgress / viewModel.dailyGoal, 1.0) : 0
        ZStack {
            Circle().stroke(lineWidth: 12).foregroundColor(.white.opacity(0.3))
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .foregroundStyle(.white)
                .rotationEffect(Angle(degrees: 270.0))
            VStack(spacing: 4) {
                if progress >= 1.0 {
                    Text("目標達成！")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else if progress > 0 {
                    Text("達成率")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(String(format: "目標まであと %d分", Int((viewModel.dailyGoal - viewModel.todaysProgress) / 60)))
                        .font(.caption.bold()).foregroundColor(.white)
                } else if viewModel.dailyGoal > 0 {
                    Text("さあ、始めよう！")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(String(format: "目標 %d分", Int(viewModel.dailyGoal / 60)))
                        .font(.title3.bold()).foregroundColor(.white)
                } else {
                    Text("目標を設定しよう！")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }
            }
        }
        .animation(.easeInOut, value: viewModel.todaysProgress)
    }
    
    
    
    private var monthlyYearlyStudyTimeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("これまでの学習記録")
                .font(DesignSystem.Fonts.title)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                HStack {
                    Text("今月の学習時間")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.monthlyStudyTime.toHourMinuteJapaneseFormat())
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                Divider()
                HStack {
                    Text("今年の学習時間")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.yearlyStudyTime.toHourMinuteJapaneseFormat())
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}
