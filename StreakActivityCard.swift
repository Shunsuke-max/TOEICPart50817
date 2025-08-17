import SwiftUI
import Charts

struct StreakActivityCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let weeklyRecords: [DailyStudyRecord]
    
    // 目標時間を分単位で受け取る
    private var dailyGoalMinutes: Int {
        Int(SettingsManager.shared.dailyGoal / 60)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 見出し
            Text("連続学習日数")
                .font(.headline)
            
            // 日数表示
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text("日")
                    .font(.title2.bold())
            }
            
            // 自己ベスト表示
            Text("自己ベスト: \(longestStreak)日")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 週の活動グラフ
            weeklyActivityChart
                .padding(.top, 8)
        }
        .padding()
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
    
    /// 週の活動（サークル＋棒グラフ）を表示する部品
    private var weeklyActivityChart: some View {
        VStack(spacing: 12) {
            // 曜日ごとの達成度サークル
            HStack {
                ForEach(weeklyRecords) { record in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                            
                            // 学習時間が目標を超えていれば円を塗りつぶす
                            if record.studyTime >= SettingsManager.shared.dailyGoal {
                                Circle()
                                    .fill(Color.orange.gradient)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .frame(width: 22, height: 22)
                        
                        VStack(spacing: 2) {
                            Text(record.id) // "月", "火", etc.
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            // 日付の数字を表示
                            Text("\(dayNumber(from: record.date))")
                                .font(.caption.bold())
                                .foregroundStyle(isToday(date: record.date) ? .orange : .primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // 棒グラフと目標ライン
            Chart(weeklyRecords) { record in
                // 目標ライン
                RuleMark(y: .value("Goal", dailyGoalMinutes))
                    .foregroundStyle(Color.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("目標 \(dailyGoalMinutes)分")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                
                // 学習時間の棒グラフ
                BarMark(
                    x: .value("Day", record.id),
                    y: .value("Minutes", record.studyTime / 60)
                )
                .foregroundStyle(Color.orange.gradient)
                .cornerRadius(4)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
    }
}

extension StreakActivityCard {
    private func dayNumber(from date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return String(day)
    }
    
    private func isToday(date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
}
