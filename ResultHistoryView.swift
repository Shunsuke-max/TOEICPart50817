
import SwiftUI
import SwiftData

struct ResultHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \QuizResult.date, order: .reverse) private var quizResults: [QuizResult]
    
    private var filteredQuizResults: [QuizResult] {
        if SettingsManager.shared.isPremiumUser {
            return quizResults
        } else {
            return Array(quizResults.prefix(5)) // 無料ユーザーは最新5件のみ表示
        }
    }
    
    @State private var selectedQuizResultForDetail: QuizResult? // ★★★ 追加 ★★★

    var body: some View {
        NavigationView {
            List {
                if filteredQuizResults.isEmpty {
                    ContentUnavailableView("まだ学習記録がありません", systemImage: "list.bullet.rectangle.portrait")
                } else {
                    ForEach(filteredQuizResults) { result in
                        ResultRowView(result: result)
                            .onTapGesture {
                                selectedQuizResultForDetail = result // ★★★ タップで選択 ★★★
                            }
                    }
                    .onDelete(perform: deleteResults)
                }
            }
            .navigationTitle("学習履歴")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            // ★★★ sheetを追加 ★★★
            .sheet(item: $selectedQuizResultForDetail) { result in
                UnifiedResultViewWrapper(quizResult: result)
            }
        }
    }

    private func deleteResults(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(quizResults[index])
        }
    }
}

// ★★★ 新しいヘルパービュー ★★★
private struct ResultRowView: View {
    let result: QuizResult
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(result.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("スコア: \(result.score) / \(result.totalQuestions)")
                .font(.headline)
            Text("正答率: \(String(format: "%.1f%%", Double(result.score) / Double(result.totalQuestions) * 100))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// ★★★ UnifiedResultViewをラップする新しいビュー ★★★
private struct UnifiedResultViewWrapper: View {
    let quizResult: QuizResult
    @State private var resultData: ResultData? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if let resultData = resultData {
                UnifiedResultView(
                    resultData: resultData,
                    isNewRecord: false, // 履歴表示なので常にfalse
                    onAction: { actionType in
                        if actionType == .backToHome {
                            dismiss()
                        }
                    }
                )
            } else {
                ProgressView("結果を読み込み中...")
                    .onAppear {
                        Task {
                            resultData = await ResultViewModel().generateResult(from: quizResult)
                        }
                    }
            }
        }
    }
}

struct ResultHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ResultHistoryView()
            .modelContainer(for: QuizResult.self, inMemory: true)
    }
}
