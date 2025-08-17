import SwiftUI
import SwiftData

struct WeaknessConquerView: View {
    @StateObject private var viewModel = WeaknessAnalysisViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundColor(DesignSystem.Colors.CourseAccent.red)
            
            Text("苦手克服モード")
                .font(.largeTitle.bold())

            Text(viewModel.isLoading ? "学習履歴を分析中..." : viewModel.analysisSummary)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(height: 50)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
            } else if !viewModel.weakQuestions.isEmpty {
                let quizSet = QuizSet(
                    setId: "WEAKNESS_CONQUER",
                    setName: "苦手克服セット",
                    questions: viewModel.weakQuestions
                )
                NavigationLink(destination: StandardQuizView(specialQuizSet: quizSet, timeLimit: SettingsManager.shared.timerDuration)) {
                    Text("テストを始める (\(viewModel.weakQuestions.count)問)")
                        .font(DesignSystem.Fonts.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(DesignSystem.Colors.CourseAccent.red)
                        .cornerRadius(DesignSystem.Elements.cornerRadius)
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.large)
        .navigationTitle("苦手克服")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 画面が表示されたら分析を開始
            await viewModel.analyzeAndFetchWeakQuestions(context: modelContext)
        }
    }
}

struct WeaknessConquerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WeaknessConquerView()
        }
    }
}
