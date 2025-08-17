import Foundation
import SwiftUI

/// アプリ内に存在する実績の種類を定義するenum
enum AchievementType: String, CaseIterable, Identifiable {
    case firstQuizCompleted
    case tenQuizzesCompleted
    case perfectScore
    case sevenDayStreak
    case weaknessConquered
    case mockTestCompleted
    case anyQuizCompleted // 任意のクイズを完了
    case highAccuracyQuiz // 高精度クイズ
    case dailyGoalAchieved // 日次目標達成

    var id: String { self.rawValue }

    // 実績のタイトル
    var title: String {
        switch self {
        case .firstQuizCompleted: return "最初の一歩"
        case .tenQuizzesCompleted: return "学習の習慣"
        case .perfectScore: return "パーフェクト！"
        case .sevenDayStreak: return "継続は力なり"
        case .weaknessConquered: return "弱点克服"
        case .mockTestCompleted: return "模擬試験マスター"
        case .anyQuizCompleted: return "学習の始まり"
        case .highAccuracyQuiz: return "正確無比"
        case .dailyGoalAchieved: return "日次目標達成"
        }
    }

    // 実績の説明
    var description: String {
        switch self {
        case .firstQuizCompleted: return "初めてクイズを完了した"
        case .tenQuizzesCompleted: return "クイズを10回完了した"
        case .perfectScore: return "いずれかのクイズで満点を獲得した"
        case .sevenDayStreak: return "「今日の一問」で7日間連続正解を達成した"
        case .weaknessConquered: return "「苦手克服モード」を初めて完了した"
        case .mockTestCompleted: return "模擬試験を完了した"
        case .anyQuizCompleted: return "任意のクイズを1回完了した"
        case .highAccuracyQuiz: return "いずれかのクイズで90%以上の正答率を達成した"
        case .dailyGoalAchieved: return "日次学習目標を達成した"
        }
    }

    // 未解除の時のアイコン
    var lockedIcon: (name: String, color: Color) {
        ("lock.fill", .gray.opacity(0.7))
    }
    
    // 解除済みの時のアイコン
    var unlockedIcon: (name: String, color: Color) {
        switch self {
        case .firstQuizCompleted: return ("figure.walk.arrival", .green)
        case .tenQuizzesCompleted: return ("books.vertical.fill", .brown)
        case .perfectScore: return ("star.fill", .yellow)
        case .sevenDayStreak: return ("flame.fill", .orange)
        case .weaknessConquered: return ("target", .red)
        case .mockTestCompleted: return ("doc.text.fill", .purple)
        case .anyQuizCompleted: return ("play.circle.fill", .blue)
        case .highAccuracyQuiz: return ("checkmark.seal.fill", .cyan)
        case .dailyGoalAchieved: return ("flag.fill", .orange)
        }
    }
}
