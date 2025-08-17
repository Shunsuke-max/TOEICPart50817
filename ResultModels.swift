import SwiftUI

// MARK: - ResultReviewItem
struct ResultReviewItem: Identifiable {
    let id = UUID()
    let question: AnyQuizQuestion // 変更: Anyから共通プロトコルへ
    let userAnswer: Int?
    let isCorrect: Bool
}

// MARK: - ResultAction (結果画面のボタン)

/// 結果画面に表示されるアクションボタンの種類を定義するenum
enum ResultActionType {
    case tryAgain
    case reviewMistakes
    case nextSet
    case backToCourse
    case backToHome
    case backToPreparation // 新しく追加
    
    /// ボタンに表示するテキスト
    var label: String {
        switch self {
        case .tryAgain: return "もう一度挑戦する"
        case .reviewMistakes: return "間違えた問題だけ復習"
        case .nextSet: return "次のセットに進む"
        case .backToCourse: return "コースに戻る"
        case .backToHome: return "ホームに戻る"
        case .backToPreparation: return "準備画面に戻る"
        }
    }
    
    /// ボタンに表示するSF Symbolアイコン
    var icon: String {
        switch self {
        case .tryAgain: return "arrow.triangle.2.circlepath"
        case .reviewMistakes: return "arrow.counterclockwise.circle.fill"
        case .nextSet: return "arrow.right.circle.fill"
        case .backToCourse: return "list.bullet.rectangle.portrait.fill"
        case .backToHome: return "house.fill"
        case .backToPreparation: return "arrow.backward.circle.fill"
        }
    }
}

/// 実際にViewに渡されるアクションボタンの情報
struct ResultAction: Identifiable {
    let id = UUID()
    let type: ResultActionType
    let isPrimary: Bool // 最も目立たせるボタンかどうか
}


// MARK: - ResultData (結果画面全体で使うデータ)

/// 統一された結果画面に表示するための、すべての情報を格納する構造体
struct ResultData: Identifiable {
    // ★★★ fullScreenCover(item:)で使うためにidを追加 ★★★
    let id = UUID()
    
    let score: Int
    let totalQuestions: Int
    let evaluation: (title: String, message: String, color: Color)
    let statistics: [(label: String, value: String)]
    let reviewableQuestions: [ResultReviewItem]
    let primaryAction: ResultAction
    let secondaryActions: [ResultAction]
    
    // ★★★ どのモードの結果かを識別するためにmodeを追加 ★★★
    let mode: Mode
    
    // 新しく追加するクイズ設定情報
    let difficulty: Int?
    let selectedSkills: [String]?
    let selectedGenres: [String]?
    let mistakeTolerance: Int?
    let timeLimit: Int?
    let selectedCourseIDs: Set<String>? // タイムアタック用
    let mistakeLimit: Int? // タイムアタック用
    
    enum Mode {
        case standard
        case timeAttack
        case survival
        case mockTest
        case vocabularyLesson
        case scramble
        case achievementTest
    }
    
    var accuracy: Double {
        totalQuestions > 0 ? Double(score) / Double(totalQuestions) : 0
    }
}