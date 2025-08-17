import SwiftUI
import SwiftData

struct BookmarkedQuestionsView: View {
    // MARK: - SwiftData Properties
    @Environment(\.modelContext) private var modelContext
    
    // dateBookmarkedが新しい順に、ブックマークされた項目をデータベースから取得
    @Query(sort: \BookmarkedQuestion.dateBookmarked, order: .reverse)
    private var bookmarkedItems: [BookmarkedQuestion]

    // MARK: - State Properties
    // 取得したブックマークIDに対応する、問題の完全なデータを保持する
    @State private var fullBookmarkedQuestions: [Question] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("ブックマークを読み込み中...")
            } else if fullBookmarkedQuestions.isEmpty {
                // ... (ブックマークがない場合の表示は変更なし)
                Spacer()
                Text("ブックマークされた問題はありません。")
                    .foregroundColor(.secondary)
                Text("クイズ中に⭐️をタップして追加しましょう。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                // クイズ開始ボタン
                NavigationLink(destination:
                    StandardQuizView(specialQuizSet: QuizSet(
                        setId: "BOOKMARKS_QUIZ",
                        setName: "ブックマークした問題",
                        questions: fullBookmarkedQuestions
                    ), timeLimit: 20)
                ) {
                    Label("ブックマーク全\(fullBookmarkedQuestions.count)問でクイズに挑戦", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(DesignSystem.Colors.CourseAccent.yellow)
                        .cornerRadius(10)
                }
                .padding()
                
                // ブックマークされた問題のリスト
                List {
                    ForEach(fullBookmarkedQuestions) { question in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(question.questionText)
                                .lineLimit(2)
                                .font(.body)
                            Text("解説: \(question.explanation)")
                                .lineLimit(1)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: removeBookmark) // スワイプで削除
                }
                .listStyle(.plain)
            }
        }
        // ★★★ .taskの代わりに.onChangeを使用 ★★★
        .onChange(of: bookmarkedItems, initial: true) {
            // データベースのブックマーク内容が変更されるたびに、
            // 問題の詳細データを読み込み直す
            Task {
                await loadFullQuestionDetails()
            }
        }
        .navigationTitle("ブックマークした問題")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// ブックマークされたIDを元に、問題の完全なデータを取得する
    private func loadFullQuestionDetails() async {
        self.isLoading = true
        
        // @Queryから取得したIDのリスト
        let bookmarkedIDs = bookmarkedItems.map { $0.questionID }
        
        do {
            let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
            let allQuestions = allCourses.flatMap { $0.quizSets.flatMap { $0.questions } }
            
            // 取得した全問題の中から、ブックマークIDに一致するものを探す
            // sortedの部分は、@Queryのソート順を維持するために必要
            let sortedQuestions = bookmarkedIDs.compactMap { id in
                allQuestions.first(where: { $0.id == id })
            }
            self.fullBookmarkedQuestions = sortedQuestions
            
        } catch {
            print("❌ Failed to load full question details for bookmarks: \(error)")
            self.fullBookmarkedQuestions = []
        }
        
        self.isLoading = false
    }
    
    /// ブックマークを削除する
    private func removeBookmark(at offsets: IndexSet) {
        for index in offsets {
            // 削除したい問題のIDを取得
            let questionToRemove = fullBookmarkedQuestions[index]
            
            // データベース内のブックマーク項目から、同じIDを持つものを探して削除
            if let itemToDelete = bookmarkedItems.first(where: { $0.questionID == questionToRemove.id }) {
                modelContext.delete(itemToDelete)
            }
        }
    }
}
