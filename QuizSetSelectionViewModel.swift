import SwiftUI
import SwiftData

@MainActor
class QuizSetSelectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var quizSets: [QuizSet] = []
    @Published var vocabQuizSets: [VocabularyQuizSet] = []
    @Published var isLoading = true
    @Published var error: Error?
    @Published var step1Status: (isComplete: Bool, isLocked: Bool) = (false, true)
    @Published var step2Status: (isComplete: Bool, isLocked: Bool) = (false, true)
    @Published var step3Status: (isComplete: Bool, isLocked: Bool) = (false, true)
    @Published var progressForSets: [String: Double] = [:]
    @Published var achievementTestQuizSet: QuizSet?
    
    // MARK: - Data Loading
    
    // ★★★ 引数をModelContextに変更 ★★★
    func loadData(for course: Course, context: ModelContext) async {
        self.isLoading = true
        self.error = nil
        
        do {
            // ★★★ ViewModel内で直接データベースから結果をフェッチする ★★★
            let descriptor = FetchDescriptor<QuizResult>()
            let allResults = try context.fetch(descriptor)

            // 全てのコースデータを一度だけ読み込む
            let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
            
            // 現在のコースに該当するデータをフィルタリングして割り当てる
            if let currentCourse = allCourses.first(where: { $0.id == course.id }) {
                self.quizSets = currentCourse.quizSets.filter { !$0.setId.hasSuffix("_ACHIEVEMENT_TEST") }
                self.achievementTestQuizSet = currentCourse.quizSets.first(where: { $0.setId.hasSuffix("_ACHIEVEMENT_TEST") })
                
                // 語彙データを割り当てる
                if let vocabInfo = findMatchingVocabLevel(for: currentCourse) {
                    self.vocabQuizSets = try await DataService.shared.loadVocabularyCourse(from: vocabInfo.jsonFileName)
                }
                
                if let setId = self.achievementTestQuizSet?.setId {
                    print("DEBUG: QuizSetSelectionViewModel - achievementTestQuizSet assigned with setId: \(setId).")
                } else {
                    print("DEBUG: QuizSetSelectionViewModel - achievementTestQuizSet is nil after assignment attempt (from loadData). Course ID: \(course.id).")
                }
            } else {
                print("⚠️ QuizSetSelectionViewModel - Current course not found in allCourses after loading details in loadData.")
            }
            
            // 読み込んだデータと全結果を元に進捗を計算
            calculateAllStepStatus(for: course, allResults: allResults)
            
        } catch {
            self.error = error
        }
        
        self.isLoading = false
    }

    private func loadQuizSets(for course: Course) async {
        do {
            // DataService.shared.loadAllCoursesWithDetails()を呼び出し、全てのコースデータを取得
            let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
            // 現在のコースに該当するクイズセットをフィルタリング
            if let currentCourse = allCourses.first(where: { $0.id == course.id }) {
                self.quizSets = currentCourse.quizSets.filter { !$0.setId.hasSuffix("_ACHIEVEMENT_TEST") }
                // 達成度テストのQuizSetを別途割り当てる
                self.achievementTestQuizSet = currentCourse.quizSets.first(where: { $0.setId.hasSuffix("_ACHIEVEMENT_TEST") })
                if let setId = self.achievementTestQuizSet?.setId {
                    print("DEBUG: QuizSetSelectionViewModel - achievementTestQuizSet assigned with setId: \(setId).")
                } else {
                    print("DEBUG: QuizSetSelectionViewModel - achievementTestQuizSet is nil after assignment attempt (from loadQuizSets). Course ID: \(course.id).")
                }
            } else {
                print("⚠️ QuizSetSelectionViewModel - Current course not found in allCourses after loading details.")
            }
        } catch {
            self.error = error
            print("❌ Error loading quiz sets in QuizSetSelectionViewModel: \(error)")
        }
    }

    private func loadVocabData(for course: Course) async {
        guard let vocabInfo = findMatchingVocabLevel(for: course) else { return }
        do {
            self.vocabQuizSets = try await DataService.shared.loadVocabularyCourse(from: vocabInfo.jsonFileName)
        } catch {
            print("語彙データの読み込みに失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Logic
    
    private func calculateAllStepStatus(for course: Course, allResults: [QuizResult]) {
        let requiredAccuracy = 0.8

        let s1Complete = !vocabQuizSets.isEmpty && vocabQuizSets.allSatisfy { getAccuracy(for: $0.setId, in: allResults) >= requiredAccuracy }
        self.step1Status = (isComplete: s1Complete, isLocked: false)
        
        let s2Complete = !quizSets.isEmpty && quizSets.allSatisfy { getAccuracy(for: $0.setId, in: allResults) >= requiredAccuracy }
        let s2Locked = !step1Status.isComplete && !SettingsManager.shared.isPremiumUser
        self.step2Status = (isComplete: s2Complete, isLocked: s2Locked)

        let testSetId = "\(course.id)_ACHIEVEMENT_TEST"
        let s3Complete = getAccuracy(for: testSetId, in: allResults) >= requiredAccuracy
        let s3Locked = (!step1Status.isComplete || !step2Status.isComplete) && !SettingsManager.shared.isPremiumUser
        self.step3Status = (isComplete: s3Complete, isLocked: s3Locked)
        
        var newProgresses: [String: Double] = [:]
            for set in self.quizSets {
                newProgresses[set.setId] = getAccuracy(for: set.setId, in: allResults)
            }
            self.progressForSets = newProgresses
    }
    
    private func getAccuracy(for setId: String, in allResults: [QuizResult]) -> Double {
        guard let result = allResults.filter({ $0.setId == setId }).max(by: { $0.score < $1.score }), result.totalQuestions > 0 else {
            return 0.0
        }
        return Double(result.score) / Double(result.totalQuestions)
    }
    
    func findMatchingVocabLevel(for course: Course) -> VocabLevelInfo? {
        let allVocabLevels: [VocabLevelInfo] = [
            .init(level: "600点コース", description: "TOEICの基礎となる必須単語", jsonFileName: "course_vocab_600.json", color: DesignSystem.Colors.CourseAccent.orange, icon: "1.circle.fill", isProFeature: false),
            .init(level: "730点コース", description: "スコアアップの鍵となる重要単語", jsonFileName: "course_vocab_730.json", color: DesignSystem.Colors.CourseAccent.green, icon: "2.circle.fill", isProFeature: false),
            .init(level: "860点コース", description: "差がつく応用・派生単語", jsonFileName: "course_vocab_860.json", color: DesignSystem.Colors.CourseAccent.blue, icon: "3.circle.fill", isProFeature: true),
            .init(level: "990点コース", description: "満点を目指すための超上級単語", jsonFileName: "course_vocab_990.json", color: DesignSystem.Colors.CourseAccent.purple, icon: "4.circle.fill", isProFeature: true)
        ]
        
        switch course.courseId {
        case "BASIC_GRAMMAR":
            return .init(level: "基礎文法", description: "基礎文法を固めるための語彙", jsonFileName: "basic_grammar_vocab.json", color: DesignSystem.Colors.CourseAccent.purple, icon: "book.closed.fill", isProFeature: false)
        case "BASIC_VOCAB":
            return .init(level: "語彙特訓", description: "基礎的な語彙力を強化", jsonFileName: "vocabulary_training_vocab.json", color: DesignSystem.Colors.CourseAccent.yellow, icon: "book.closed.fill", isProFeature: false)
        case "BIZ_VOCAB":
            return .init(level: "紛らわしい単語・語法", description: "ビジネスで役立つ語彙", jsonFileName: "confusing_words_vocab.json", color: DesignSystem.Colors.CourseAccent.red, icon: "book.closed.fill", isProFeature: false)
        default:
            let score = course.courseName.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if !score.isEmpty {
                return allVocabLevels.first { $0.level.contains(score) }
            }
            return nil
        }
    }
}
