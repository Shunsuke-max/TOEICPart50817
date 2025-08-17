import SwiftUI
import SwiftData

struct ReviewQuizSetupView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 復習対象のアイテムと、それに対応する問題データを保持
    @State private var reviewItems: [ReviewItem] = []
    @State private var reviewQuestions: [Question] = []
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let reviewManager: ReviewManager // ReviewManagerのインスタンスを追加
    
    init() {
        self.reviewManager = ReviewManager() // ReviewManagerを初期化
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            
            if isLoading {
                ProgressView("復習問題を準備中...")
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
            } else {
                // 準備が完了したら、クイズ画面へ遷移
                // isPresentedを.constant(true)にすることで、このViewが表示されたら即座にクイズ画面をモーダルで表示
                ReviewQuizFlowView(reviewItems: reviewItems, questions: reviewQuestions, modelContext: modelContext) // modelContextを渡す
            }
        }
        .task {
            await prepareReviewQuiz()
        }
        .navigationTitle("今日の復習")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func prepareReviewQuiz() async {
        // 1. 今日の復習アイテムを取得
        let allItems = await reviewManager.fetchAllReviewItems(modelContext: modelContext) // 全てのアイテムを取得
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let items = allItems.filter { item in
            item.nextReview <= today
        }
        
        guard !items.isEmpty else {
            self.errorMessage = "復習する問題はありません。"
            self.isLoading = false
            return
        }
        self.reviewItems = items
        
        // 無料ユーザーの場合、復習アイテムの数を制限
        if !SettingsManager.shared.isPremiumUser && self.reviewItems.count > 20 {
            self.reviewItems = Array(self.reviewItems.prefix(20))
            self.errorMessage = "無料版では復習できる問題が20問に制限されています。Pro版で全ての復習問題を解放しましょう！"
        }
        
        let reviewIDs = items.map { $0.questionID }
        
        // 2. IDを元に、問題の詳細データを取得
        do {
            let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
            let allQuestions = allCourses.flatMap { $0.quizSets.flatMap { $0.questions } }
            
            // 取得した全問題の中から、復習IDに一致するものを探す
            // 復習アイテムの順番を維持するようにソート
            let sortedQuestions = reviewIDs.compactMap { id in
                allQuestions.first(where: { $0.id == id })
            }
            self.reviewQuestions = sortedQuestions
            
        } catch {
            self.errorMessage = "問題の読み込みに失敗しました。"
            print("❌ Failed to load full question details for review: \(error)")
        }
        
        self.isLoading = false
    }
}
