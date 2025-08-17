import Foundation
import FirebaseStorage

struct MockTestInfo: Codable, Identifiable {
    var id: String { setId }
    let setId: String
    let setName: String
    let fileName: String
    let description: String
    let questionCount: Int
    let estimatedTimeMinutes: Int
}

enum DataServiceError: Error, LocalizedError {
    case noQuizSetFound(String)

    var errorDescription: String? {
        switch self {
        case .noQuizSetFound(let fileName):
            return "指定されたファイルからクイズセットが見つかりませんでした: \(fileName)"
        }
    }
}

class DataService {
    static let shared = DataService()
    
    // ★★★ 全問題データをキャッシュするための変数を追加 ★★★
    private var allQuestionsCache: [Question]?
    
    private init() {}

    func loadCourseManifest() async throws -> [Course] {
        let storageRef = Storage.storage().reference(withPath: "courses_manifest.json")
        do {
            let data = try await storageRef.data(maxSize: 1 * 1024 * 1024)
            let courses = try JSONDecoder().decode([Course].self, from: data)
            Swift.print("✅ Course manifest loaded successfully.")
            // ★★★ デバッグログを追加 ★★★
            for course in courses {
                Swift.print("Loaded Course: \(course.courseName), Lessons: \(course.totalLessons ?? 0), Time: \(course.estimatedStudyTime ?? 0), Tags: \(course.learningTags?.joined(separator: ", ") ?? "None")")
            }
            return courses
        } catch {
            Swift.print("❌ Failed to load course manifest from Firebase Storage.")
            if let decodingError = error as? DecodingError {
                Swift.print("Decoding Error: \(decodingError)")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    Swift.print("Type Mismatch for \(type) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    Swift.print("Value Not Found for \(type) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    Swift.print("Key Not Found: \(key.stringValue) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    Swift.print("Data Corrupted: \(context.debugDescription)")
                @unknown default:
                    Swift.print("Unknown Decoding Error: \(decodingError.localizedDescription)")
                }
            } else {
                Swift.print("Other Error: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    func loadQuizSets(forCourse course: Course) async throws -> [QuizSet] {
        let storageRef = Storage.storage().reference(withPath: course.dataFileName)
        let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
        let wrapper = try JSONDecoder().decode(QuizSetDataWrapper.self, from: data)
        Swift.print("✅ Quiz sets loaded for \(course.courseName). Set IDs: \(wrapper.quizSets.map { $0.setId }.joined(separator: ", "))")
        return wrapper.quizSets
    }
    
    // ★★★ getAllQuestions関数を追加し、loadAllCoursesWithDetailsを修正 ★★★
    
    /// キャッシュを考慮して、全てのコースの問題を取得する
    func getAllQuestions() async throws -> [Question] {
        // もしキャッシュがあれば、即座にキャッシュを返す
        if let cachedQuestions = allQuestionsCache {
            Swift.print("✅ All questions served from cache.")
            return cachedQuestions
        }
        
        // キャッシュがなければ、全データを読み込む
        let courses = try await loadAllCoursesWithDetails()
        let allQuestions = courses.flatMap { $0.quizSets.flatMap { $0.questions } }
        
        // 読み込んだデータをキャッシュに保存
        self.allQuestionsCache = allQuestions
        Swift.print("✅ All questions loaded and cached.")
        
        return allQuestions
    }
    
    // ▼▼▼【修正箇所】▼▼▼
    // このブロック全体を loadAllCoursesWithDetails という一つの関数にまとめました。
    func loadAllCoursesWithDetails() async throws -> [Course] {
        let courses = try await loadCourseManifest()
        var detailedCourses: [Course] = []
        
        await withTaskGroup(of: Course?.self) { group in
            for course in courses {
                group.addTask {
                    do {
                        var currentCourse = course
                        Swift.print("DEBUG: Processing course: \(currentCourse.courseName) (ID: \(currentCourse.courseId))")
                        var quizSets = try await self.loadQuizSets(forCourse: currentCourse)
                        
                        // 達成度テストのQuizSetを動的に生成し、追加
                        // courseIdが"course_XXX"の形式の場合のみ達成度テストを生成
                        Swift.print("DEBUG: Checking courseId for achievement test generation: \(currentCourse.courseId)")
                        guard currentCourse.courseId.hasPrefix("SCORE_") else {
                            Swift.print("⚠️ Skipping achievement test generation for course: \(currentCourse.courseName) as it does not have a score-based courseId.")
                            currentCourse.quizSets = quizSets
                            return currentCourse
                        }
                        let scoreLevel = currentCourse.courseId.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                        Swift.print("DEBUG: Extracted scoreLevel: \(scoreLevel) for course: \(currentCourse.courseName).")
                        Swift.print("DEBUG: Score level extracted: \(scoreLevel)")
                        
                        var achievementTestQuestions: [Question] = []
                        var loadedQuestionIDs: Set<String> = []
                        
                        // course_vocab_XXX.json から問題を読み込む
                        let vocabFileName = "course_vocab_\(scoreLevel).json"
                        Swift.print("DEBUG: Vocab file name: \(vocabFileName).")
                        Swift.print("DEBUG: Attempting to load vocab file: \(vocabFileName)")
                        do {
                            let vocabQuestions = try await self.loadQuestionsFromFile(fileName: vocabFileName)
                            for question in vocabQuestions {
                                if !loadedQuestionIDs.contains(question.id) {
                                    achievementTestQuestions.append(question)
                                    loadedQuestionIDs.insert(question.id)
                                }
                            }
                            Swift.print("DEBUG: Loaded \(vocabQuestions.count) vocab questions from \(vocabFileName).")
                        } catch DataServiceError.noQuizSetFound {
                            Swift.print("⚠️ Vocab quiz set not found for \(vocabFileName). Skipping.")
                        } catch {
                            Swift.print("❌ Failed to load vocab quiz set from \(vocabFileName). Error: \(error.localizedDescription)")
                        }
                        
                        // course_score_XXX.json から問題を読み込む
                        let scoreFileName = "course_score_\(scoreLevel).json"
                        Swift.print("DEBUG: Score file name: \(scoreFileName).")
                        Swift.print("DEBUG: Attempting to load score file: \(scoreFileName)")
                        do {
                            let scoreQuestions = try await self.loadQuestionsFromFile(fileName: scoreFileName)
                            for question in scoreQuestions {
                                if !loadedQuestionIDs.contains(question.id) {
                                    achievementTestQuestions.append(question)
                                    loadedQuestionIDs.insert(question.id)
                                }
                            }
                            Swift.print("DEBUG: Loaded \(scoreQuestions.count) score questions from \(scoreFileName).")
                        } catch DataServiceError.noQuizSetFound {
                            Swift.print("⚠️ Score quiz set not found for \(scoreFileName). Skipping.")
                        } catch {
                            Swift.print("❌ Failed to load score quiz set from \(scoreFileName). Error: \(error.localizedDescription)")
                        }
                        
                        // 結合した問題リストから達成度テスト用のQuizSetを作成
                        if !achievementTestQuestions.isEmpty {
                            // 問題をシャッフルし、最大20問に制限
                            let shuffledQuestions = achievementTestQuestions.shuffled().prefix(20).map { $0 }
                            let achievementTestQuizSet = QuizSet(
                                setId: "\(currentCourse.courseId.uppercased())_ACHIEVEMENT_TEST",
                                setName: "\(currentCourse.courseName) 達成度テスト",
                                questions: shuffledQuestions
                            )
                            quizSets.append(achievementTestQuizSet)
                            Swift.print("DEBUG: Added achievement test QuizSet with setId: \(achievementTestQuizSet.setId) to course \(currentCourse.courseName).")
                            Swift.print("DEBUG: Current quizSets for \(currentCourse.courseName): \(quizSets.map { $0.setId }.joined(separator: ", "))")
                            Swift.print("DEBUG: Generated achievement test with \(shuffledQuestions.count) questions for \(currentCourse.courseName).")
                        } else {
                            Swift.print("⚠️ No questions found for achievement test for \(currentCourse.courseName). Skipping generation. Current achievementTestQuestions count: \(achievementTestQuestions.count)")
                        }
                        
                        currentCourse.quizSets = quizSets
                        return currentCourse
                    } catch {
                        Swift.print("⚠️ Failed to load details for course: \(course.courseName). Error: \(error)")
                        return nil
                    }
                }
            }
            for await course in group {
                if let course = course {
                    detailedCourses.append(course)
                }
            }
        }
        Swift.print("✅ All courses with details loaded.")
        return detailedCourses
    }
    // ▲▲▲【修正箇所】▲▲▲
    
    func loadQuizSet(from fileName: String) async throws -> QuizSet {
        let storageRef = Storage.storage().reference(withPath: fileName)
        do {
            let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
            let wrapper = try JSONDecoder().decode(QuizSetDataWrapper.self, from: data)
            guard let quizSet = wrapper.quizSets.first else {
                throw DataServiceError.noQuizSetFound(fileName)
            }
            Swift.print("✅ Quiz set loaded from \(fileName). Total questions: \(quizSet.questions.count)")
            return quizSet
        } catch {
            Swift.print("❌ Failed to load quiz set from \(fileName).")
            if let decodingError = error as? DecodingError {
                Swift.print("Decoding Error: \(decodingError)")
            } else {
                Swift.print("Other Error: \(error.localizedDescription)")
            }
            throw error
        }
    }

    func loadScrambleQuizSet(from fileName: String) async throws -> ScrambleQuizSet {
        let storageRef = Storage.storage().reference(withPath: fileName)
        do {
            let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
            let quizSet = try JSONDecoder().decode(ScrambleQuizSet.self, from: data)
            Swift.print("✅ Scramble quiz set loaded from \(fileName).")
            return quizSet
        } catch {
            Swift.print("❌ Failed to load Scramble quiz set from \(fileName).")
            if let decodingError = error as? DecodingError {
                Swift.print("Decoding Error: \(decodingError)")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    Swift.print("Type Mismatch for \(type) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    Swift.print("Value Not Found for \(type) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    Swift.print("Key Not Found: \(key.stringValue) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    Swift.print("Data Corrupted: \(context.debugDescription)")
                @unknown default:
                    Swift.print("Unknown Decoding Error: \(decodingError.localizedDescription)")
                }
            } else {
                Swift.print("Other Error: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    func loadVocabularyCourse(from fileName: String) async throws -> [VocabularyQuizSet] {
        let storageRef = Storage.storage().reference(withPath: fileName)
        do {
            let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
            let decodedData = try JSONDecoder().decode(VocabularyQuizData.self, from: data)
            Swift.print("✅ Vocabulary course loaded successfully from \(fileName).")
            return decodedData.quizSets
        } catch {
            Swift.print("❌ Failed to load vocabulary course from \(fileName).")
            if let decodingError = error as? DecodingError {
                Swift.print("Decoding Error: \(decodingError)")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    Swift.print("Type Mismatch for \(type) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    Swift.print("Value Not Found for \(type) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    Swift.print("Key Not Found: \(key.stringValue) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    Swift.print("Data Corrupted: \(context.debugDescription)")
                @unknown default:
                    Swift.print("Unknown Decoding Error: \(decodingError.localizedDescription)")
                }
            } else {
                Swift.print("Other Error: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    func loadMockTestSet(fileName: String) async throws -> [Question] {
        let storageRef = Storage.storage().reference(withPath: fileName)
        let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
        let wrapper = try JSONDecoder().decode(QuizSetDataWrapper.self, from: data)
        return wrapper.quizSets.first?.questions ?? []
    }
    
    func loadMockTestManifest() async throws -> [MockTestInfo] {
        let storageRef = Storage.storage().reference(withPath: "mock_test_manifest.json")
        let data = try await storageRef.data(maxSize: 1 * 1024 * 1024)
        return try JSONDecoder().decode([MockTestInfo].self, from: data)
    }

    // 新しく追加するヘルパー関数
    private func loadQuestionsFromFile(fileName: String) async throws -> [Question] {
        let storageRef = Storage.storage().reference(withPath: fileName)
        do {
            let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
            
            // QuizSetDataWrapperとしてデコードを試みる
            if let wrapper = try? JSONDecoder().decode(QuizSetDataWrapper.self, from: data) {
                return wrapper.quizSets.flatMap { $0.questions }
            }
            
            // VocabularyQuizDataとしてデコードを試みる
            if let vocabData = try? JSONDecoder().decode(VocabularyQuizData.self, from: data) {
                return vocabData.quizSets.flatMap { $0.questions.map { $0.toQuestion() } }
            }
            
            throw DataServiceError.noQuizSetFound(fileName)
        } catch {
            Swift.print("❌ Failed to load questions from \(fileName): \(error)")
            throw error
        }
    }
    func loadSyntaxScrambleSet(from fileName: String) async throws -> SyntaxScrambleQuizSet {
        let storageRef = Storage.storage().reference(withPath: fileName)
        do {
            // 5MBの上限でメモリに直接ダウンロード
            let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
            
            let quizSet = try JSONDecoder().decode(SyntaxScrambleQuizSet.self, from: data)
            Swift.print("✅ Syntax Scramble quiz set loaded from \(fileName).")
            return quizSet
        } catch {
            Swift.print("❌ Failed to load Syntax Scramble quiz set from \(fileName).")
            if let decodingError = error as? DecodingError {
                Swift.print("Decoding Error: \(decodingError)")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    Swift.print("Type Mismatch for \(type) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    Swift.print("Value Not Found for \(type) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    Swift.print("Key Not Found: \(key.stringValue) at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug Description: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    Swift.print("Data Corrupted: \(context.debugDescription)")
                @unknown default:
                    Swift.print("Unknown Decoding Error: \(decodingError.localizedDescription)")
                }
            } else {
                Swift.print("Other Error: \(error.localizedDescription)")
            }
            throw error
        }
    }

    func loadLocalSyntaxScrambleSet(from fileName: String) throws -> SyntaxScrambleQuizSet {
        guard let url = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json") else {
            Swift.print("❌ Local file \(fileName) not found in bundle.")
            throw URLError(.fileDoesNotExist)
        }
        do {
            let data = try Data(contentsOf: url)
            let quizSet = try JSONDecoder().decode(SyntaxScrambleQuizSet.self, from: data)
            Swift.print("✅ Local Syntax Scramble quiz set loaded from \(fileName).")
            return quizSet
        } catch {
            Swift.print("❌ Failed to load local Syntax Scramble quiz set from \(fileName): \(error)")
            throw error
        }
    }
    func loadOnimonQuestions() async throws -> [Question] {
            let storageRef = Storage.storage().reference(withPath: "onimon_questions.json")
            let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
            let wrapper = try JSONDecoder().decode(QuizSetDataWrapper.self, from: data)
            // 最初のクイズセットに含まれる問題を返す（シャッフルはViewModelで行う）
            return wrapper.quizSets.first?.questions ?? []
        }

    func getQuizSet(byId setId: String) async throws -> QuizSet? {
        let courses = try await loadAllCoursesWithDetails()
        for course in courses {
            if let quizSet = course.quizSets.first(where: { $0.setId == setId }) {
                return quizSet
            }
        }
        return nil
    }
}
