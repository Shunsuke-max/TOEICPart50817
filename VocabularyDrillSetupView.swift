import SwiftUI

/// 単語ドリルの練習内容を設定する画面
struct VocabularyDrillSetupView: View {
    
    // 選択可能なレベルの情報
    private let levels: [VocabLevelInfo] = [
        .init(level: "600点コース", description: "TOEICの基礎となる必須単語", jsonFileName: "course_vocab_600.json", color: DesignSystem.Colors.CourseAccent.orange, icon: "1.circle.fill", isProFeature: false),
        .init(level: "730点コース", description: "スコアアップの鍵となる重要単語", jsonFileName: "course_vocab_730.json", color: DesignSystem.Colors.CourseAccent.green, icon: "2.circle.fill", isProFeature: false),
        .init(level: "860点コース", description: "差がつく応用・派生単語", jsonFileName: "course_vocab_860.json", color: .blue, icon: "3.circle.fill", isProFeature: true),
        .init(level: "990点コース", description: "満点を目指すための超上級単語", jsonFileName: "course_vocab_990.json", color: .purple, icon: "4.circle.fill", isProFeature: true)
    ]
    
    @State private var showingPaywall = false // Paywall表示用State
    @State private var allLevelsSelected: Bool = false // すべて選択/解除用State
    
    // ユーザーが選択した設定を保持するState
    @State private var selectedLevelFileNames: Set<String> = []
    @State private var selectedQuestionCount: Int = 10
    private let questionCountOptions = [10, 20, 50]
    
    // データ読み込みとクイズ遷移のためのState
    @State private var questions: [VocabularyQuestion]?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToQuiz = false
    @State private var selectedAccentColor: Color? // 追加
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 30) {
                
                // --- レベル選択セクション ---
                VStack(alignment: .leading, spacing: 16) {
                    Text("1. 練習したいレベルを選択（複数可）")
                        .font(.headline)
                    
                    SelectAllButton(selectedLevelFileNames: $selectedLevelFileNames, levels: levels, isPremiumUser: SettingsManager.shared.isPremiumUser)
                    
                    ForEach(levels) { level in
                        levelRow(for: level)
                    }
                }
                
                // --- 問題数選択セクション ---
                QuestionCountSelectionView(selectedQuestionCount: $selectedQuestionCount, questionCountOptions: questionCountOptions)
                
                Spacer()
                
                // --- 開始ボタン ---
                makeDrillStartButton()
                
                // エラーメッセージ表示
                ErrorMessageView(errorMessage: errorMessage)
            }
            .padding()
            .background(
                // クイズ画面への非表示NavigationLink
                NavigationLink(destination: quizDestinationView(), isActive: $navigateToQuiz) {
                    EmptyView()
                }
            )
        }
        .navigationTitle("単語ドリル設定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    /// 各レベルの選択肢を表示するUI部品
    @ViewBuilder
    private func levelRow(for level: VocabLevelInfo) -> some View {
        let isSelected = selectedLevelFileNames.contains(level.jsonFileName)
        
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .green : .secondary)
                .font(.title2)
            
            VStack(alignment: .leading) {
                LevelTitleView(level: level)
                Text(level.description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            withAnimation {
                if level.isProFeature {
                    showingPaywall = true
                } else {
                    if isSelected {
                        selectedLevelFileNames.remove(level.jsonFileName)
                    } else {
                        selectedLevelFileNames.insert(level.jsonFileName)
                    }
                }
            }
        }
    }
    
    /// クイズの準備と開始を行う非同期関数
    private func prepareAndStartDrill() async {
        isLoading = true
        errorMessage = nil
        
        do {
            var fetchedQuestions: [VocabularyQuestion] = []
            var tempAccentColor: Color? = nil // 一時的にアクセントカラーを保持
            
            // 選択された全てのレベルから問題を非同期で並行して取得
            try await withThrowingTaskGroup(of: ([VocabularyQuestion], Color?).self) { group in // Color?も返すように変更
                for fileName in selectedLevelFileNames {
                    group.addTask {
                        let vocabSets = try await DataService.shared.loadVocabularyCourse(from: fileName)
                        let questions = vocabSets.flatMap { $0.questions }
                        // 選択されたレベルのアクセントカラーを取得
                        let levelInfo = levels.first(where: { $0.jsonFileName == fileName })
                        return (questions, levelInfo?.color)
                    }
                }
                
                for try await (questions, accentColor) in group {
                    fetchedQuestions.append(contentsOf: questions)
                    // 複数のレベルが選択された場合、最初のレベルの色を代表として採用（またはより複雑なロジック）
                    if tempAccentColor == nil { 
                        tempAccentColor = accentColor 
                    }
                }
            }
            
            // 問題がなければエラー表示
            guard !fetchedQuestions.isEmpty else {
                errorMessage = "選択されたレベルに問題がありません。"
                isLoading = false
                return
            }
            
            // シャッフルして指定された数だけ問題を取り出す
            let drillQuestions = Array(fetchedQuestions.shuffled().prefix(selectedQuestionCount))
            self.questions = drillQuestions
            self.selectedAccentColor = tempAccentColor // 取得したアクセントカラーをStateに保存
            
            // クイズ画面へ遷移
            navigateToQuiz = true
            
        } catch {
            errorMessage = "問題の読み込みに失敗しました。"
            print("❌ Failed to load vocab drill questions: \(error)")
        }
        
        isLoading = false
    }
    
    /// クイズ画面（遷移先）を生成する
    @ViewBuilder
    private func quizDestinationView() -> some View {
        if let questions = questions {
            let drillVocabQuizSet = VocabularyQuizSet(
                setId: "VOCAB_DRILL_\(UUID().uuidString)",
                setName: "単語ドリル",
                order: 0, // 仮の値
                questions: questions
            )
            VocabularyLessonQuizView(vocabSet: drillVocabQuizSet, onQuizCompleted: nil, accentColor: selectedAccentColor ?? .blue)
        } else {
            EmptyView()
        }
    }

    private func makeDrillStartButton() -> some View {
        DrillStartButton(isLoading: isLoading, selectedLevelFileNames: selectedLevelFileNames, prepareAndStartDrill: prepareAndStartDrill)
    }
}
