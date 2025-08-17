import SwiftUI
import SwiftData

struct MockTestStartView: View {
    let testInfo: MockTestInfo
    
    @Query private var quizResults: [QuizResult]

    // Computed properties for last and best scores
    private var lastScore: QuizResult? {
        quizResults
            .filter { $0.setId == testInfo.setId }
            .sorted { $0.date > $1.date }
            .first
    }

    private var bestScore: QuizResult? {
        quizResults
            .filter { $0.setId == testInfo.setId }
            .sorted { $0.score > $1.score }
            .first
    }
    
    // 状態管理用のプロパティ
    @State private var questions: [Question]?
    @State private var session: MockTestSession?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // ★★★ ナビゲーションを制御するためのStateを追加 ★★★
    @State private var navigateToQuiz = false
    @State private var showCountdown: Bool = false
    
    var body: some View {
        ZStack {
            if showCountdown && !navigateToQuiz { // Only show countdown if not navigating to quiz yet
                CountdownView(countFrom: 3, onFinished: {
                    navigateToQuiz = true
                })
            } else if !showCountdown && !navigateToQuiz { // Show main content if neither countdown nor quiz is active
                VStack(spacing: 24) { // 全体のスペーシングを調整
                    Spacer()
                    
                    Image(systemName: "doc.text.clock.fill")
                        .font(.system(size: 80))
                        .foregroundColor(DesignSystem.Colors.CourseAccent.indigo)

                    VStack(spacing: 5) {
                        Text("準備はいいですか？")
                            .font(.title.bold()) // 1行目を太字に
                            .foregroundColor(.primary) // 少し濃い色に

                        Text("集中して、ベストを尽くしましょう！")
                            .font(.headline) // 2行目を少し細く
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                    // --- インフォメーションカード ---
                    VStack(alignment: .leading, spacing: 15) {
                        // ★★★ 説明文にアイコンを追加して視認性を向上 ★★★
                        Label("問題数: \(testInfo.questionCount)問", systemImage: "list.bullet.rectangle.portrait")
                        Label("制限時間: \(testInfo.estimatedTimeMinutes)分", systemImage: "timer")

                        if let lastScore = lastScore {
                            Divider()
                            Text("過去の成績")
                                .font(.headline)
                            Label("前回スコア: \(lastScore.score)/\(lastScore.totalQuestions)問 (\(Int(lastScore.duration / 60))分\(Int(lastScore.duration.truncatingRemainder(dividingBy: 60)))秒)", systemImage: "clock.arrow.circlepath")
                        }

                        if let bestScore = bestScore {
                            if lastScore == nil { Divider() } // Only add divider if lastScore is not present
                            Label("ベストスコア: \(bestScore.score)/\(bestScore.totalQuestions)問 (\(Int(bestScore.duration / 60))分\(Int(bestScore.duration.truncatingRemainder(dividingBy: 60)))秒)", systemImage: "star.fill")
                        }
                    }
                    .font(.title3)
                    .padding(20) // パディングを少し増やす
                    .background(.regularMaterial)
                    .cornerRadius(16)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    Spacer() // バランス調整のためSpacerを追加
                    
                    // --- 開始ボタン ---
                    if isLoading {
                        ProgressView()
                    } else {
                        Button(action: {
                            prepareAndStartMockTest()
                        }) {
                            Text("テストを開始")
                                .font(DesignSystem.Fonts.headline.bold())
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.Colors.CourseAccent.indigo.gradient) // グラデーションを追加
                                .cornerRadius(DesignSystem.Elements.cornerRadius)
                        }
                    }
                }
                .padding(30)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $navigateToQuiz) {
            if let session = session, let questions = questions {
                MockTestView(session: session, questions: questions)
                    .onDisappear { // Reset showCountdown when MockTestView is dismissed
                        showCountdown = false
                    }
            }
        }
    }
    
    private func prepareAndStartMockTest() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fetchedQuestions = try await DataService.shared.loadMockTestSet(fileName: testInfo.fileName)
                
                guard fetchedQuestions.count >= 30 else {
                    self.errorMessage = "問題数が不足しています。"
                    self.isLoading = false
                    return
                }
                
                let testQuestions = Array(fetchedQuestions.shuffled().prefix(30))
                
                // セッションを開始
                self.session = MockTestManager.shared.startTest(questions: testQuestions, setId: testInfo.setId)
                self.questions = testQuestions
                
                // 全ての準備が整ったら、カウントダウンを開始
                self.showCountdown = true
                
            } catch {
                self.errorMessage = "問題の読み込みに失敗しました。"
                print("❌ Failed to load mock test questions: \(error)")
            }
            self.isLoading = false
        }
    }
}
