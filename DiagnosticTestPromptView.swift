import SwiftUI

struct DiagnosticTestPromptView: View {
    // このViewを閉じるためのアクション
    var onComplete: () -> Void
    
    @State private var diagnosticQuizSet: QuizSet?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("最後に")
                .font(DesignSystem.Fonts.title)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Text("実力診断テストに挑戦しませんか？")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("現在のあなたの実力を測るため、全コースからバランス良く30問を抽出しました。結果を元に、今後の学習計画を立てましょう！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
            
            if isLoading {
                ProgressView("テストを準備中...")
            } else if let quizSet = diagnosticQuizSet {
                NavigationLink(destination: StandardQuizView(specialQuizSet: quizSet, timeLimit: SettingsManager.shared.timerDuration)) {
                    Text("実力診断を始める")
                        .font(DesignSystem.Fonts.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(DesignSystem.Colors.brandPrimary)
                        .cornerRadius(DesignSystem.Elements.cornerRadius)
                }
            }
            
            Button("あとでする") {
                onComplete()
            }
            .padding(.top, 10)
            
        }
        .padding(DesignSystem.Spacing.large)
        .task {
            await prepareDiagnosticTest()
        }
    }
    
    private func prepareDiagnosticTest() async {
        do {
            let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
            let allQuestions = allCourses.flatMap { $0.quizSets.flatMap { $0.questions } }.shuffled()
            
            // 30問に満たない場合は、あるだけの問題でテストする
            let testQuestions = Array(allQuestions.prefix(30))
            
            guard !testQuestions.isEmpty else {
                print("⚠️ No questions available for diagnostic test.")
                isLoading = false
                return
            }
            
            self.diagnosticQuizSet = QuizSet(setId: "DIAGNOSTIC_TEST", setName: "実力診断テスト", questions: testQuestions)
            
        } catch {
            print("❌ Failed to prepare diagnostic test: \(error)")
        }
        isLoading = false
    }
}
