import SwiftUI
import SwiftData

struct QuizStartPromptView: View {
    let quizSet: QuizSet? // Optionalに変更
    let vocabQuizSet: VocabularyQuizSet? // 追加
    let course: Course?
    let allSetsInCourse: [QuizSet]?
    let vocabAccentColor: Color? // 追加
    
    @State private var selectedTimeLimit: Int
    @State private var isQuizPresented = false // モーダル表示用の状態変数
    @Query private var allResults: [QuizResult]
    
    private let durationOptions = [10, 20, 30, 60]
    private let timerOffValue = SettingsManager.shared.timerOffValue

    // MARK: - Initializers
    
    // 通常のコースから呼び出されるinit
    init(quizSet: QuizSet, course: Course, allSetsInCourse: [QuizSet]) {
        self.quizSet = quizSet
        self.vocabQuizSet = nil // 通常のコースではnil
        self.course = course
        self.allSetsInCourse = allSetsInCourse
        self.vocabAccentColor = nil // 通常のコースではnil
        _selectedTimeLimit = State(initialValue: SettingsManager.shared.timerDuration)
    }
    
    // ★★★ 語彙クイズなど、コース情報がない場合に使われるinitを新しく追加 ★★★
    init(specialQuizSet: QuizSet, allSets: [QuizSet]? = nil, vocabAccentColor: Color? = nil, course: Course? = nil) {
        self.quizSet = specialQuizSet
        self.vocabQuizSet = nil
        self.course = course // ここを修正
        self.allSetsInCourse = allSets
        self.vocabAccentColor = vocabAccentColor
        _selectedTimeLimit = State(initialValue: SettingsManager.shared.timerDuration)
    }

    // ★★★ VocabularyQuizSetを受け取るinitを新しく追加 ★★★
    init(specialVocabQuizSet: VocabularyQuizSet, vocabAccentColor: Color? = nil) {
        self.quizSet = nil // VocabularyQuizSetが渡された場合はnil
        self.vocabQuizSet = specialVocabQuizSet
        self.course = nil
        self.allSetsInCourse = nil
        self.vocabAccentColor = vocabAccentColor
        _selectedTimeLimit = State(initialValue: SettingsManager.shared.timerDuration)
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // ★★★ 新しいヘッダー情報エリア ★★★
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    // アイコン
                    Image(systemName: course?.courseIcon ?? "text.book.closed.fill")
                        .font(.system(size: 40))
                        .foregroundColor(course?.courseColor ?? DesignSystem.Colors.brandPrimary)
                    
                    // タイトル
                    Text(quizSet?.setName ?? "")
                        .font(.title.bold())
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                
                // 自己ベストと獲得報酬
                HStack(spacing: 24) {
                    Spacer()
                    VStack {
                        Text("自己ベスト")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let bestScore = findBestScore() {
                            Text("\(bestScore.score) / \(bestScore.totalQuestions)")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                        } else {
                            Text("- / -")
                                .font(.title2.bold())
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    
                    Spacer()
                }
            }

            // 問題数・制限時間カード
            VStack(alignment: .leading, spacing: 15) {
                Label("問題数: \(quizSet?.questions.count ?? 0)問", systemImage: "list.number")
                HStack {
                    Label("制限時間:", systemImage: "timer")
                    Spacer()
                    Picker("制限時間", selection: $selectedTimeLimit) {
                        Text("なし").tag(timerOffValue)
                        ForEach(durationOptions, id: \.self) { duration in
                            Text("\(duration)秒").tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.accentColor)
                }
            }
            .font(.headline)
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            
            Spacer()
            
            // クイズ開始ボタン
            Button(action: { isQuizPresented = true }) {
                Text("クイズ開始")
                    .font(DesignSystem.Fonts.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(course?.courseColor.gradient ?? DesignSystem.Colors.brandPrimary.gradient)
                    .cornerRadius(DesignSystem.Elements.cornerRadius)
            }
        }
        .padding(DesignSystem.Spacing.large)
        .navigationTitle("クイズの準備")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isQuizPresented) {
            destinationView()
        }
    }
    
    @ViewBuilder
    private func destinationView() -> some View {
        if let course = course, let allSets = allSetsInCourse, let quizSet = quizSet {
            // 通常のコースの場合
            QuizContainerView(
                quizSet: quizSet,
                course: course,
                allSetsInCourse: allSets,
                timeLimit: selectedTimeLimit,
                quizDisplayMode: quizSet.setId.hasSuffix("_ACHIEVEMENT_TEST") ? .achievementTest : .standard // ここを修正
            )
        } else if let vocabQuizSet = vocabQuizSet {
            // 語彙クイズの場合
            VocabularyLessonQuizView(
                vocabSet: vocabQuizSet,
                onQuizCompleted: nil, // 必要に応じて設定
                accentColor: vocabAccentColor ?? DesignSystem.Colors.brandPrimary // デフォルト色を設定
            )
        } else if let quizSet = quizSet {
            // その他の特殊なQuizSetの場合
            QuizContainerView(
                quizSet: quizSet,
                course: self.course, // self.courseを渡すように修正
                allSetsInCourse: self.allSetsInCourse,
                timeLimit: selectedTimeLimit,
                vocabAccentColor: vocabAccentColor,
                quizDisplayMode: quizSet.setId.hasSuffix("_ACHIEVEMENT_TEST") ? .achievementTest : .standard // ここを追加
            )
        } else {
            EmptyView()
        }
    }
    
    private func findBestScore() -> QuizResult? {
        guard let quizSet = quizSet else { return nil }
        return allResults
            .filter { $0.setId == quizSet.setId }
            .max(by: { $0.score < $1.score })
    }
}
