import Foundation
import SwiftUI

// MissionType.swift

enum MissionType: String, CaseIterable, Codable, Identifiable {
    var id: String { self.rawValue }
    
    // --- ミッションのケースを定義 ---
    case solve10Problems      // 問題を10問解く
    case achieveDailyGoal     // 今日の学習目標を達成する
    case completeReview       // 復習を完了する
    case get90PercentAccuracy // 正答率90%以上を達成する
    
    
    // 修正点①: `var title: String { ... }` のように、computed propertyとして正しく定義する
    /// ミッションのタイトル
    var title: String {
        switch self {
        case .solve10Problems:
            return "問題を10問解く"
        case .achieveDailyGoal:
            return "今日の学習目標を達成"
        case .completeReview:
            return "復習セッションを完了"
        case .get90PercentAccuracy:
            return "正答率90%を達成"
        }
    }
    
    // 修正点②: `targetCount` も同様に computed property として定義する
    /// ミッション達成に必要なカウント
    var targetCount: Int {
        switch self {
        case .solve10Problems:
            return 10
        case .achieveDailyGoal:
            return 1
        case .completeReview:
            return 1
        case .get90PercentAccuracy:
            return 90 // パーセント表記なので90
        }
    }
    
    /// ミッションの進捗タイプ
    var progressType: ProgressType {
        switch self {
        case .solve10Problems, .achieveDailyGoal, .completeReview:
            return .count
        case .get90PercentAccuracy:
            return .percentage
        }
    }
    
    /// ミッションのアイコン
    var iconName: String {
        switch self {
        case .solve10Problems:
            return "pencil.line"
        case .achieveDailyGoal:
            return "target"
        case .completeReview:
            return "arrow.triangle.2.circlepath"
        case .get90PercentAccuracy:
            return "chart.pie.fill"
        }
    }
    
    /// ミッションアイコンの色
    var iconColor: Color {
        switch self {
        case .solve10Problems:
            return .blue
        case .achieveDailyGoal:
            return .orange
        case .completeReview:
            return .green
        case .get90PercentAccuracy:
            return .purple
        }
    }
    
    // --- イベントに応じたミッション進捗を返すロジック ---
    // この部分は MissionManager での使われ方に応じて実装が異なります。
    // 以下は一例です。
    
    // イベントの種類
    enum EventType {
        case problemsSolved(count: Int)
        case dailyGoalAchieved
        case reviewCompleted
        case quizSessionFinished(accuracy: Double) // 正答率 (0.0 ~ 1.0)
    }
    
    /// イベントが発生した際に、このミッションタイプの進捗がどれだけ進むかを返す
    func progress(for event: EventType) -> Int {
        switch (self, event) {
        case (.solve10Problems, .problemsSolved(let count)):
            return count
        case (.achieveDailyGoal, .dailyGoalAchieved):
            return 1
        case (.completeReview, .reviewCompleted):
            return 1
        case (.get90PercentAccuracy, .quizSessionFinished(let accuracy)):
            // 正答率が目標以上なら達成（1）、そうでなければ進捗なし（0）
            return Int(accuracy * 100) >= self.targetCount ? self.targetCount : 0
        default:
            return 0 // 関係ないイベントなら進捗は0
        }
    }
}

/// ミッションの進捗管理方法
enum ProgressType {
    case count      // 例: 10回中3回完了
    case percentage // 例: 90%達成
}
