import SwiftUI

struct ScrambleQuizListView: View {
    @StateObject private var viewModel = ScrambleMapViewModel()
    @State private var path = NavigationPath() // ナビゲーションパスをStateとして保持
    
    var body: some View {
        NavigationStack(path: $path) { // NavigationStackを使用
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    Text("エラー: \(error.localizedDescription)")
                } else {
                    ScrambleMapView(sections: viewModel.sections)
                }
            }
            .navigationDestination(for: SyntaxScrambleQuestion.self) { question in
                ScrambleLevelDetailView(level: question.difficultyLevel, questions: [question])
            }
            .navigationTitle("並び替えマップ")
            .navigationBarTitleDisplayMode(.inline)
            
            .task {
                await viewModel.loadQuestions()
            }
            .onReceive(ScrambleProgressManager.shared.$completedIDs) { _ in
                viewModel.refreshProgress()
            }
        }
    }
}

struct ScrambleQuizListView_Previews: PreviewProvider {
    static var previews: some View {
        ScrambleQuizListView()
    }
}
