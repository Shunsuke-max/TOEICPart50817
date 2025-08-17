import Foundation
import Combine // Combineフレームワークをインポート

/// 並び替え問題の進捗を管理するクラス
class ScrambleProgressManager: ObservableObject { // ObservableObjectに準拠
    
    static let shared = ScrambleProgressManager()
    
    private let completedIDsKey = "scrambleCompletedIDsKey"
    @Published private(set) var completedIDs: Set<String> { // @Published を追加
        didSet {
            // completedIDsが変更されたらUserDefaultsに保存
            UserDefaults.standard.set(Array(completedIDs), forKey: completedIDsKey)
            print("✅ ScrambleProgressManager: completedIDs saved: \(completedIDs)")
        }
    }
    
    private init() {
        // アプリ起動時に、保存されているクリア済みIDを読み込む
        let loadedIDs = Set(UserDefaults.standard.stringArray(forKey: completedIDsKey) ?? [])
        self.completedIDs = loadedIDs
        print("✅ ScrambleProgressManager: completedIDs loaded: \(completedIDs)")
    }
    
    /// 指定されたIDの問題がクリア済みかチェックする
    func isCompleted(id: String) -> Bool {
        return completedIDs.contains(id)
    }
    
    /// 問題をクリア済みとして記録する
    func markAsCompleted(id: String) {
        completedIDs.insert(id)
        print("並び替え問題クリア済みとして記録: \(id)")
    }

    func getProgress(for questions: [SyntaxScrambleQuestion]) -> (completed: Int, total: Int) {
        // 問題リストからIDのSetを生成
        let questionIDsInLevel = Set(questions.map { $0.id })
        // クリア済みのID Setと、引数の問題ID Setの共通部分（積集合）を計算
        let completedCount = self.completedIDs.intersection(questionIDsInLevel).count
        return (completed: completedCount, total: questions.count)
    }
    
    func getCompletedIDs() -> Set<String> {
            return self.completedIDs
        }

    /// 特定の難易度レベルの全てのクイズが完了したかチェックする
    func isDifficultyLevelCompleted(level: Int, allQuestions: [SyntaxScrambleQuestion]) -> Bool {
        let questionsInLevel = allQuestions.filter { $0.difficultyLevel == level }
        guard !questionsInLevel.isEmpty else { return true } // その難易度レベルに問題がない場合は完了とみなす
        let completedCountInLevel = questionsInLevel.filter { completedIDs.contains($0.id) }.count
        return completedCountInLevel == questionsInLevel.count
    }
}
