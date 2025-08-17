import Foundation
import SwiftUI
import SwiftData

// MARK: - Question Model
// 問題１つ分のデータモデル（変更なし）
struct Question: Identifiable, Codable {
    let id: String
    let questionText: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String
    let category: String? // Optionalに変更
    let difficultyLevel: String? // 新しく追加
    let skillTags: [String]? // 新しく追加

    // Codableのカスタムinitを追加
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.questionText = try container.decode(String.self, forKey: .questionText)
        self.options = try container.decode([String].self, forKey: .options)
        self.correctAnswerIndex = try container.decode(Int.self, forKey: .correctAnswerIndex)
        self.explanation = try container.decode(String.self, forKey: .explanation)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel) // 新しく追加
        self.skillTags = try container.decodeIfPresent([String].self, forKey: .skillTags) // 新しく追加
    }

    // CodableのCodingKeysを追加
    private enum CodingKeys: String, CodingKey {
        case id, questionText, options, correctAnswerIndex, explanation, category, difficultyLevel, skillTags
    }
    
    // convenience init for easy creation (optional, but good practice)
    init(id: String, questionText: String, options: [String], correctAnswerIndex: Int, explanation: String, category: String? = nil, difficultyLevel: String? = nil, skillTags: [String]? = nil) {
        self.id = id
        self.questionText = questionText
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
        self.explanation = explanation
        self.category = category
        self.difficultyLevel = difficultyLevel
        self.skillTags = skillTags
    }
}

// MARK: - QuizSet Model
// コースに含まれる個別のクイズセットのデータモデル
struct QuizSet: Identifiable, Codable {
    var id: String { setId }
    let setId: String
    let setName: String
    let questions: [Question]
}

// ★★★ 新しく追加：コース別JSONのトップレベル構造体 ★★★
struct QuizSetDataWrapper: Codable {
    let quizSets: [QuizSet]
}


// MARK: - Course Model
// クイズのコース全体を表すトップレベルのデータモデル
struct Course: Identifiable, Codable, Equatable {
    static func == (lhs: Course, rhs: Course) -> Bool {
            return lhs.id == rhs.id
        }
    var id: String { courseId }
    
    let courseId: String
    let courseName: String
    let courseIcon: String
    let courseDescription: String
    
    let dataFileName: String
    
    var quizSets: [QuizSet] = []

    // JSON内の "courseColor" (文字列) を受け取るためのプロパティ
    private let courseColorName: String?
    
    // 新しく追加するプロパティ
    let totalLessons: Int?
    let estimatedStudyTime: Int? // minutes
    let learningTags: [String]?
    let unlockCondition: String? // 例: "SCORE_600_COMPLETED"
    var isRecommended: Bool? = false // デフォルトはfalse
    
    var courseColor: Color {
        guard let colorName = courseColorName else { return .gray }
        switch colorName.lowercased() {
        case "orange": return DesignSystem.Colors.CourseAccent.orange
        case "green": return DesignSystem.Colors.CourseAccent.green
        case "blue": return DesignSystem.Colors.CourseAccent.blue
        case "indigo": return DesignSystem.Colors.CourseAccent.indigo
        case "purple": return DesignSystem.Colors.CourseAccent.purple
        case "yellow": return DesignSystem.Colors.CourseAccent.yellow
        case "red": return DesignSystem.Colors.CourseAccent.red
        default: return .gray
        }
    }
    
    // JSONのキー名とSwiftのプロパティ名を対応させる
    enum CodingKeys: String, CodingKey {
        case courseId, courseName, courseIcon, courseDescription, dataFileName
        case courseColorName = "courseColor"
        case totalLessons, estimatedStudyTime, learningTags, unlockCondition, isRecommended
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.courseId = try container.decode(String.self, forKey: .courseId)
        self.courseName = try container.decode(String.self, forKey: .courseName)
        self.courseIcon = try container.decode(String.self, forKey: .courseIcon)
        self.courseDescription = try container.decode(String.self, forKey: .courseDescription)
        self.dataFileName = try container.decode(String.self, forKey: .dataFileName)
        self.courseColorName = try container.decodeIfPresent(String.self, forKey: .courseColorName)
        
        self.totalLessons = try container.decodeIfPresent(Int.self, forKey: .totalLessons)
        self.estimatedStudyTime = try container.decodeIfPresent(Int.self, forKey: .estimatedStudyTime)
        self.learningTags = try container.decodeIfPresent([String].self, forKey: .learningTags)
        self.unlockCondition = try container.decodeIfPresent(String.self, forKey: .unlockCondition)
        self.isRecommended = try container.decodeIfPresent(Bool.self, forKey: .isRecommended)
    }
}

extension Question {
    /// 選択肢をシャッフルし、正しい答えのインデックスを更新した新しいQuestionインスタンスを返すメソッド
    func shuffled() -> Question {
        // 1. 元の正しい選択肢の文字列を取得
        let correctAnswerText = self.options[self.correctAnswerIndex]
        
        // 2. 選択肢の配列をシャッフル
        let shuffledOptions = self.options.shuffled()
        
        // 3. シャッフル後の配列から、元の正しい選択肢がどのインデックスに移動したか検索
        guard let newCorrectIndex = shuffledOptions.firstIndex(of: correctAnswerText) else {
            // 万が一見つからない場合は、元のQuestionをそのまま返す（エラー回避）
            return self
        }
        
        // 4. シャッフルされた選択肢と、新しい正しいインデックスを持つ新しいQuestionインスタンスを生成して返す
        return Question(
            id: self.id,
            questionText: self.questionText,
            options: shuffledOptions,
            correctAnswerIndex: newCorrectIndex,
            explanation: self.explanation,
            category: self.category // ここを追加
        )
    }
}

// MARK: - QuizResult Model (SwiftData)
@Model
final class QuizResult {
    @Attribute(.unique) var id: UUID
    var setId: String // どのクイズセットからの結果か
    var score: Int
    var totalQuestions: Int
    var date: Date
    var incorrectQuestionIDs: [String] // 間違えた問題のID
    var duration: TimeInterval // 学習時間 (秒)
    
    init(id: UUID, setId: String, score: Int, totalQuestions: Int, date: Date, incorrectQuestionIDs: [String], duration: TimeInterval) {
        self.id = id
        self.setId = setId
        self.score = score
        self.totalQuestions = totalQuestions
        self.date = date
        self.incorrectQuestionIDs = incorrectQuestionIDs
        self.duration = duration
    }
}



// MARK: - Vocabulary Models
struct VocabularyQuizData: Codable {
    let quizSets: [VocabularyQuizSet]
}

struct VocabularyQuizSet: Identifiable, Codable {
    var id: String { setId }
    let setId: String
    let setName: String
    let order: Int // 新しく追加する順序プロパティ
    var questions: [VocabularyQuestion]
    var isUnlocked: Bool = false // アンロック状態を示すプロパティ

    // Codableのカスタムinitを追加
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.setId = try container.decode(String.self, forKey: .setId)
        self.setName = try container.decode(String.self, forKey: .setName)
        self.order = try container.decode(Int.self, forKey: .order)
        self.questions = try container.decode([VocabularyQuestion].self, forKey: .questions)
        self.isUnlocked = false // デフォルトはロック状態
    }

    // CodableのCodingKeysを追加
    private enum CodingKeys: String, CodingKey {
        case setId, setName, order, questions
    }
    
    // このイニシャライザを追加
    init(setId: String, setName: String, order: Int, questions: [VocabularyQuestion]) {
        self.setId = setId
        self.setName = setName
        self.order = order
        self.questions = questions
        self.isUnlocked = false // デフォルト値
    }
}

struct VocabularyQuestion: Identifiable, Codable {
    let id: String
    let questionText: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String
    let word: String // 単語
    let meaning: String // 意味
    let exampleSentence: String // 例文
    let exampleSentenceTranslation: String? // 例文の日本語訳 (Optional)
    let relatedExpressions: [String]? // 関連表現 (Optional)
}

extension VocabularyQuestion {
    /// 選択肢をシャッフルし、正しい答えのインデックスを更新した新しいVocabularyQuestionインスタンスを返すメソッド
    func shuffled() -> VocabularyQuestion {
        // 1. 元の正しい選択肢の文字列を取得
        let correctAnswerText = self.options[self.correctAnswerIndex]

        // 2. 選択肢の配列をシャッフル
        let shuffledOptions = self.options.shuffled()

        // 3. シャッフル後の配列から、元の正しい選択肢がどのインデックスに移動したか検索
        guard let newCorrectIndex = shuffledOptions.firstIndex(of: correctAnswerText) else {
            // 万が一見つからない場合は、元のVocabularyQuestionをそのまま返す（エラー回避）
            return self
        }

        // 4. シャッフルされた選択肢と、新しい正しいインデックスを持つ新しいVocabularyQuestionインスタンスを生成して返す
        return VocabularyQuestion(
            id: self.id,
            questionText: self.questionText,
            options: shuffledOptions,
            correctAnswerIndex: newCorrectIndex,
            explanation: self.explanation,
            word: self.word,
            meaning: self.meaning,
            exampleSentence: self.exampleSentence,
            exampleSentenceTranslation: self.exampleSentenceTranslation,
            relatedExpressions: self.relatedExpressions
        )
    }

    /// VocabularyQuestionをQuestion型に変換するヘルパーメソッド
    func toQuestion() -> Question {
        return Question(
            id: self.id,
            questionText: self.questionText,
            options: self.options,
            correctAnswerIndex: self.correctAnswerIndex,
            explanation: self.explanation,
            category: "Vocabulary" // カテゴリを任意で設定
        )
    }
}

// MARK: - Scramble Models
struct ScrambleQuizSet: Codable {
    let quizzes: [ScrambleQuiz]
}

struct ScrambleQuiz: Identifiable, Codable {
    var id: String { quizId }
    let quizId: String
    let quizName: String
    let questions: [ScrambleQuestion]
}

struct ScrambleQuestion: Identifiable, Codable {
    let id: String
    let sentence: String
    let correctOrder: [String]
    let explanation: String
}

// MARK: - Syntax Scramble Models
struct SyntaxScrambleQuizSet: Codable {
    let syntaxScrambleQuestions: [SyntaxScrambleQuestion]
}

struct SyntaxScrambleQuestion: Identifiable, Codable, Hashable {
    let id: String
    let questionText: String
    let chunks: [Chunk] // 正しい順序のチャンク
    let difficultyLevel: Int // 1, 2, 3
    let explanation: String
    let theme: String // テーマプロパティ
    let skill: String // 追加
    let genre: String // 追加
}

import UniformTypeIdentifiers

struct Chunk: Codable, Hashable, Identifiable, Transferable {
    let id = UUID()
    let text: String // 元のテキストをそのまま保持
    let isFixed: Bool
    let syntaxRole: String

    // Codableのカスタムinitを追加
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text) // JSONの"text"をそのままデコード
        self.isFixed = try container.decode(Bool.self, forKey: .isFixed)
        self.syntaxRole = try container.decode(String.self, forKey: .syntaxRole)
    }

    // エンコード用（textをエンコード）
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(isFixed, forKey: .isFixed)
        try container.encode(syntaxRole, forKey: .syntaxRole)
    }

    private enum CodingKeys: String, CodingKey {
        case text, isFixed, syntaxRole
    }
    
    // MARK: - Transferable Conformance
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

// MARK: - ReviewedSyntaxSprintQuestion Model
struct ReviewedSyntaxSprintQuestion: Identifiable {
    let id = UUID()
    let question: SyntaxScrambleQuestion
    let userAnswer: [Chunk]
    let isCorrect: Bool
}

// MARK: - Analysis Models (New)
struct SkillTagAnalysis: Identifiable {
    let id: String // Skill Tag Name
    var totalQuestions: Int = 0
    var totalCorrect: Int = 0
    var accuracy: Double {
        totalQuestions == 0 ? 0 : (Double(totalCorrect) / Double(totalQuestions)) * 100
    }
}

struct DifficultyAnalysis: Identifiable {
    let id: String // Difficulty Level Name
    var totalQuestions: Int = 0
    var totalCorrect: Int = 0
    var accuracy: Double {
        totalQuestions == 0 ? 0 : (Double(totalCorrect) / Double(totalQuestions)) * 100
    }
}

// MARK: - Common Protocol for all Question Types
protocol AnyQuizQuestion: Identifiable {
    var id: String { get }
    var explanation: String { get } // 全ての質問タイプに共通するプロパティ
    // 必要に応じて、他の共通プロパティを追加
}

// 各問題モデルがAnyQuizQuestionに準拠するように拡張
extension Question: AnyQuizQuestion {}
extension VocabularyQuestion: AnyQuizQuestion {} // ScrambleQuestionではなくSyntaxScrambleQuestion

enum QuizDisplayMode {
    case standard // 通常のクイズ（単語学習など）
    case practice // 実践問題
    case achievementTest // 達成度テスト
}
extension SyntaxScrambleQuestion: AnyQuizQuestion {} // ScrambleQuestionではなくSyntaxScrambleQuestion
