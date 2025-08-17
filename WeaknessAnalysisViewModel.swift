import Foundation
import SwiftData

@MainActor
class WeaknessAnalysisViewModel: ObservableObject {
    @Published var weakQuestions: [Question] = []
    @Published var isLoading = false
    @Published var analysisSummary: String = ""

    /// SwiftDataのコンテキストを元に、苦手な問題を分析・抽出する
    func analyzeAndFetchWeakQuestions(context: ModelContext) async {
        self.isLoading = true
        self.analysisSummary = "学習履歴を分析中..."

        do {
            // 1. 全てのクイズ結果をデータベースから取得
            let descriptor = FetchDescriptor<QuizResult>()
            let allResults = try context.fetch(descriptor)
            
            // 2. 正答率が80%未満だったクイズの結果のみをフィルタリング
            //    (本当に苦手だった時の間違いを重視するため)
            let lowScoreResults = allResults.filter { result in
                guard result.totalQuestions > 0 else { return false }
                let accuracy = Double(result.score) / Double(result.totalQuestions)
                return accuracy < 0.8
            }
            
            // 3. フィルタリングされた結果から、間違えた問題IDを全て集計
            let incorrectIDs = lowScoreResults.flatMap { $0.incorrectQuestionIDs }
            
            // 4. 不正解回数が多い順に並び替え、上位10件を取得
            let incorrectCounts = incorrectIDs.reduce(into: [:]) { counts, id in counts[id, default: 0] += 1 }
            let top10WeakIDs = incorrectCounts.sorted { $0.value > $1.value }.prefix(10).map { $0.key }

            guard !top10WeakIDs.isEmpty else {
                self.analysisSummary = "分析の結果、特に苦手な問題は見つかりませんでした。素晴らしいです！"
                self.isLoading = false
                return
            }
            
            // 5. IDを元に、問題の詳細データを取得
            let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
            let allQuestions = allCourses.flatMap { $0.quizSets.flatMap { $0.questions } }
            
            self.weakQuestions = top10WeakIDs.compactMap { id in
                allQuestions.first(where: { $0.id == id })
            }
            
            self.analysisSummary = "特に苦手な\(weakQuestions.count)問を抽出しました。挑戦して完璧にしましょう！"
            
        } catch {
            self.analysisSummary = "分析中にエラーが発生しました。"
            print("❌ Weakness analysis failed: \(error)")
        }
        
        self.isLoading = false
    }
}
