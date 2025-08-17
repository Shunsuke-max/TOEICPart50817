import Foundation
import SwiftData

/// 学習ストリーク（継続日数）を保持するための構造体
struct StudyStreak {
    let current: Int // 現在の連続学習日数
    let longest: Int // これまでの最長連続学習日数
}

@MainActor
class StudyCalendarViewModel: ObservableObject {
    @Published var studiedDates: Set<DateComponents> = []
    @Published var streak: StudyStreak = StudyStreak(current: 0, longest: 0)

    /// クイズ結果の配列から、学習日とストリークを計算する
    func process(results: [QuizResult]) {
            // resultsが空の場合でもストリークを0にリセットして処理を続ける
            guard !results.isEmpty else {
                self.studiedDates = []
                self.streak = StudyStreak(current: 0, longest: 0)
                return
            }
            
            // 日付の重複をなくし、昇順にソート
            let uniqueSortedDates = Set(results.map { Calendar.current.startOfDay(for: $0.date) }).sorted()
            
            // カレンダーでハイライトするための日付セットを生成
            self.studiedDates = Set(uniqueSortedDates.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) })
            
            // ストリークを計算
            self.streak = calculateStreaks(from: uniqueSortedDates)
        }

    /// ソート済みのユニークな日付配列から、現在および最長のストリークを計算する
    private func calculateStreaks(from dates: [Date]) -> StudyStreak {
        guard !dates.isEmpty else { return StudyStreak(current: 0, longest: 0) }

        var longestStreak = 0
        var currentStreak = 0
        
        // 最初の要素で初期化
        longestStreak = 1
        currentStreak = 1

        for i in 1..<dates.count {
            let previousDate = dates[i-1]
            let currentDate = dates[i]
            
            // 日付が1日違い（連続している）かチェック
            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: previousDate), nextDay == currentDate {
                currentStreak += 1
            } else {
                // 連続が途切れたらリセット
                currentStreak = 1
            }
            
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        }
        
        // 最後の日の連続が今日まで続いているかチェック
        // datesの最後の日付が昨日、もしくは今日であるか
        if let lastDate = dates.last {
            if !Calendar.current.isDateInToday(lastDate) && !Calendar.current.isDateInYesterday(lastDate) {
                 // 最後の日付が今日でも昨日でもなければ、現在のストリークは0
                currentStreak = 0
            }
        }

        return StudyStreak(current: currentStreak, longest: longestStreak)
    }
}
