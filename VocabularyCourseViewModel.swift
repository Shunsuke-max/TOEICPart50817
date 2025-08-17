import Foundation
import Combine

@MainActor
class VocabularyCourseViewModel: ObservableObject {
    
    @Published var quizSets: [VocabularyQuizSet] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let dataService: DataService
    // ★★★ どのJSONファイルを読み込むかを保持するプロパティを追加 ★★★
    private let fileName: String
    
    // ★★★ イニシャライザを修正し、ファイル名を受け取るように変更 ★★★
    init(fileName: String, dataService: DataService = .shared) {
        self.fileName = fileName
        self.dataService = dataService
    }
    
    func fetchVocabularyCourse() async {
        guard !isLoading else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // ★★★ ハードコードされていたファイル名を、プロパティを参照するように変更 ★★★
            var fetchedSets = try await dataService.loadVocabularyCourse(from: self.fileName)
            
            // orderに基づいてソート
            fetchedSets.sort { $0.order < $1.order }
            
            // アンロック状態を設定
            let unlockedSets = SettingsManager.shared.unlockedVocabularySets
            self.quizSets = fetchedSets.map { set in
                var mutableSet = set
                if SettingsManager.shared.isPremiumUser {
                    // Proユーザーは全てアンロック
                    mutableSet.isUnlocked = true
                } else {
                    // 無料ユーザーは最初のセットのみアンロック
                    mutableSet.isUnlocked = unlockedSets.contains(set.setId) || set.order == 1
                }
                return mutableSet
            }
            
        } catch {
            self.errorMessage = "コースの読み込みに失敗しました。\n(\(error.localizedDescription))"
            print("❌ Failed to fetch vocabulary course from \(self.fileName): \(error)")
        }
        
        self.isLoading = false
    }
}
