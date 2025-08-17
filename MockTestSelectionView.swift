import SwiftUI
import SwiftData

struct MockTestSelectionView: View {
    @State private var mockTests: [MockTestInfo] = []
    @State private var isLoading = true
    
    @Query(sort: \QuizResult.date, order: .reverse) private var allResults: [QuizResult]
    
    @State private var showPaywall = false
    @State private var selection: String?
    
    private var isPremiumUser: Bool {
        SettingsManager.shared.isPremiumUser
    }
    
    var body: some View {
        ZStack {
            // 背景色は常に表示
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            // ★★★ ここからが修正箇所 ★★★
            if isLoading {
                // ロード中は、画面中央にインジケーターを大きく表示
                ProgressView("模試を読み込んでいます...")
            } else {
                // ロード完了後にリストを表示
                mainContentView
            }
            // ★★★ ここまでが修正箇所 ★★★
        }
        .navigationTitle("模試を選択")
        .task {
            // .taskはZStackに移動しても問題なく動作します
            do {
                // 読み込みが早く完了しすぎるとちらつくため、意図的に少し待つ
                try await Task.sleep(for: .seconds(0.5))
                self.mockTests = try await DataService.shared.loadMockTestManifest()
            } catch {
                print("❌ Failed to load mock test manifest: \(error)")
            }
            self.isLoading = false
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // ★★★ 新設: ロード完了後のメインコンテンツを分離 ★★★
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 16) { // spacingを調整
                
                // ★★★ このVStackをここに追加 ★★★
                if !isPremiumUser {
                    VStack(spacing: 12) {
                        Text("全ての模試を解放し、学習を加速させよう")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showPaywall = true }) {
                            Label("Proにアップグレード", systemImage: "sparkles")
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(16)
                }
                if mockTests.isEmpty {
                    Text("利用可能な模試はありません。")
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                } else {
                    ForEach(mockTests) { testInfo in
                        
                        let isLocked = !isPremiumUser && testInfo.id != mockTests.first?.id
                        let bestScore = getBestScore(for: testInfo.id)
                        let isRecommended = testInfo.id == getRecommendedTestID()
                        
                        Button(action: {
                            if isLocked {
                                showPaywall = true
                            } else {
                                selection = testInfo.id
                            }
                        }) {
                            mockTestRow(
                                testInfo: testInfo,
                                isLocked: isLocked,
                                isRecommended: isPremiumUser && isRecommended,
                                bestScore: bestScore
                            )
                            .background(
                                NavigationLink(
                                    destination: MockTestGatewayView(testInfo: testInfo),
                                    tag: testInfo.id,
                                    selection: $selection,
                                    label: { EmptyView() }
                                )
                                .opacity(0)
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .onDisappear {
            selection = nil
        }
    }
    
    /// 指定されたIDの模試の最高スコアを取得する
    private func getBestScore(for setId: String) -> QuizResult? {
        return allResults
            .filter { $0.setId == setId }
            .max(by: { $0.score < $1.score })
    }
    
    /// Proユーザー向けに、次におすすめする模試のIDを返す
    private func getRecommendedTestID() -> String? {
        let completedTestIDs = Set(allResults.map { $0.setId })
        let recommendedTest = mockTests.first { test in
            !completedTestIDs.contains(test.id)
        }
        return recommendedTest?.id ?? mockTests.last?.id
    }
    
    @ViewBuilder
    private func mockTestButton(for index: Int) -> some View {
        let testInfo = mockTests[index]
        
        // --- 計算ロジック (変更なし) ---
        let isPreviousTestCleared: Bool = (index == 0) ? true : {
            let prevId = mockTests[index - 1].id
            guard let prevResult = getBestScore(for: prevId) else { return false }
            let accuracy = Double(prevResult.score) / Double(prevResult.totalQuestions)
            return accuracy >= 0.8
        }()
        let isLocked = !isPremiumUser && !isPreviousTestCleared
        let bestScore = getBestScore(for: testInfo.id)
        let isRecommended = testInfo.id == getRecommendedTestID()
        
        // ★★★ ここからが修正箇所 ★★★
        
        // Buttonで囲むのをやめ、mockTestRowを直接表示
        mockTestRow(
            testInfo: testInfo,
            isLocked: isLocked,
            isRecommended: isPremiumUser && isRecommended,
            bestScore: bestScore
        )
        .background(
            NavigationLink(
                destination: MockTestGatewayView(testInfo: testInfo),
                tag: testInfo.id,
                selection: $selection,
                label: { EmptyView() }
            )
            .opacity(0)
        )
        // ★★★ .onTapGestureでタップ時の処理を定義 ★★★
        .onTapGesture {
            if isLocked {
                showPaywall = true
            } else {
                selection = testInfo.id
            }
        }
    }
    
    @ViewBuilder
    private func mockTestRow(testInfo: MockTestInfo, isLocked: Bool, isRecommended: Bool, bestScore: QuizResult?) -> some View {
        let progress = (bestScore != nil && bestScore!.totalQuestions > 0) ? Double(bestScore!.score) / Double(bestScore!.totalQuestions) : 0.0
        let isPerfect = progress >= 1.0
        let statusText = bestScore != nil ? "最高スコア: \(bestScore!.score) / \(bestScore!.totalQuestions)" : "\(testInfo.questionCount)問 / \(testInfo.estimatedTimeMinutes)分"
        let accentColor: Color = isLocked ? .gray : (isPerfect ? .yellow : .indigo)
        
        VStack(alignment: .leading, spacing: 12) {
            // --- 上段：アイコンとタイトル ---
            HStack {
                Image(systemName: isLocked ? "lock.fill" : "doc.text.fill")
                    .font(.title2.bold()).foregroundColor(.white).frame(width: 50, height: 50)
                    .background(accentColor.gradient).cornerRadius(12)
                
                Text(testInfo.setName).font(.headline.bold()).foregroundColor(.primary)
                Spacer()
                if isRecommended {
                    Text("おすすめ").font(.caption2.bold()).foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Color.pink))
                }
            }
            // ★★★ isLocked時にこの部分だけを半透明に ★★★
            .opacity(isLocked ? 0.7 : 1.0)
            
            // --- 中段：売り文句（説明文） ---
            Text(testInfo.description)
                .font(.caption)
                .foregroundColor(.secondary) // ★ 常に同じ濃さで表示
            
            Divider()
            
            // --- 下段：ステータス情報 ---
            HStack {
                // ★★★ アイコンを "star.fill" から "info.circle.fill" に変更 ★★★
                Label(statusText, systemImage: "info.circle.fill")
                Spacer()
                if isPerfect {
                    Label("Perfect!", systemImage: "crown.fill").foregroundColor(accentColor)
                }
            }
            .font(.caption.bold())
            .foregroundColor(bestScore != nil ? accentColor : .secondary)
            // ★★★ isLocked時にこの部分だけを半透明に ★★★
            .opacity(isLocked ? 0.7 : 1.0)
        }
        .padding()
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(16)
        // ★★★ カード全体にかかっていたopacityは削除 ★★★
    }
}
