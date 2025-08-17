import Foundation
import SwiftUI
import SwiftData

struct DailyPerformance: Identifiable {
    let id: Date
    let accuracy: Double // 0-100%
}

// ★★★ 追加: 弱点問題表示用のIdentifiableな構造体 ★★★
struct IncorrectQuestionItem: Identifiable {
    let id: String // QuestionのIDを使用
    let question: Question
    let count: Int
}

// CourseAnalysis 構造体を修正
struct CourseAnalysis: Identifiable {
    // IDをコースIDに変更し、堅牢にする
    var id: String { course.id }
    
    // Courseオブジェクト自体を保持する
    let course: Course
    
    // courseNameとcourseColorはcourseオブジェクトから取得できるように変更
    var courseName: String { course.courseName }
    var courseColor: Color { course.courseColor }
    
    var totalCorrect: Int = 0
    var totalQuestions: Int = 0
    var accuracy: Double {
        totalQuestions == 0 ? 0 : (Double(totalCorrect) / Double(totalQuestions)) * 100
    }
}

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var courseAnalyses: [CourseAnalysis] = []
    @Published var topIncorrectQuestions: [IncorrectQuestionItem] = []
    @Published var performanceOverTime: [DailyPerformance] = []
    @Published var totalStudyTimeFormatted: String = "計算中..."
    @Published var overallAccuracy: Double = 0
    @Published var totalQuestionsAnswered: Int = 0
    @Published var totalCorrectAnswers: Int = 0
    @Published var studyDaysCount: Int = 0
    @Published var todayStudyTime: TimeInterval = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var weeklyRecords: [DailyStudyRecord] = []
    @Published var monthlyStudyTime: TimeInterval = 0
    @Published var yearlyStudyTime: TimeInterval = 0
    @Published var skillTagAnalyses: [SkillTagAnalysis] = [] // 新しく追加
    @Published var difficultyAnalyses: [DifficultyAnalysis] = [] // 新しく追加

    func calculateAnalytics(with allResults: [QuizResult]) async {
        
        guard let allCourses = try? await DataService.shared.loadAllCoursesWithDetails() else {
            return
        }
        
        // 全てのQuestionをIDでマップする辞書を作成
        let allQuestionsMap = Dictionary(uniqueKeysWithValues: allCourses.flatMap { $0.quizSets.flatMap { $0.questions } }.map { ($0.id, $0) })

        // 1. コースごとの正答率を計算
        var analysisDict: [String: CourseAnalysis] = [:]
        for course in allCourses {
            if course.quizSets.isEmpty { continue }
            analysisDict[course.id] = CourseAnalysis(course: course)
        }
        
        for result in allResults {
            if let course = allCourses.first(where: { c in c.quizSets.contains(where: { $0.setId == result.setId }) }) {
                analysisDict[course.id]?.totalCorrect += result.score
                analysisDict[course.id]?.totalQuestions += result.totalQuestions
            }
        }
        self.courseAnalyses = analysisDict.values.filter { $0.totalQuestions > 0 }.sorted { $0.accuracy > $1.accuracy }

        // 2. 最も苦手な問題を計算
        let allIncorrectIDs = allResults.flatMap { $0.incorrectQuestionIDs }
        let incorrectCounts = allIncorrectIDs.reduce(into: [:]) { counts, id in counts[id, default: 0] += 1 }
        let top5IDsAndCounts = incorrectCounts.sorted { $0.value > $1.value }.prefix(5)
        self.topIncorrectQuestions = top5IDsAndCounts.compactMap { id, count in
            if let question = allQuestionsMap[id] { // allQuestionsMapを使用
                return IncorrectQuestionItem(id: question.id, question: question, count: count)
            }
            return nil
        }
        
        // 3. 全体の統計情報を計算
        let totalCorrect = courseAnalyses.reduce(0) { $0 + $1.totalCorrect }
        let totalQuestions = courseAnalyses.reduce(0) { $0 + $1.totalQuestions }
        self.totalCorrectAnswers = totalCorrect
        self.totalQuestionsAnswered = totalQuestions
        self.overallAccuracy = totalQuestions == 0 ? 0 : (Double(totalCorrect) / Double(totalQuestions)) * 100

        // 4. 合計学習時間を取得
        let totalTimeForPeriod = allResults.reduce(0) { $0 + $1.duration }
        self.totalStudyTimeFormatted = format(duration: totalTimeForPeriod)
        
        // 5. 時系列の成績を計算
        let groupedByDay = Dictionary(grouping: allResults) { result in Calendar.current.startOfDay(for: result.date) }
        let dailyPerformances = groupedByDay.map { (date, resultsOnDay) -> DailyPerformance in
            let totalCorrectOnDay = resultsOnDay.reduce(0) { $0 + $1.score }
            let totalQuestionsOnDay = resultsOnDay.reduce(0) { $0 + $1.totalQuestions }
            let accuracy = totalQuestionsOnDay > 0 ? (Double(totalCorrectOnDay) / Double(totalQuestionsOnDay)) * 100 : 0
            return DailyPerformance(id: date, accuracy: accuracy)
        }
        self.performanceOverTime = dailyPerformances.sorted(by: { $0.id < $1.id })
        
        // ★★★ ここからが新しい計算処理 ★★★
        
        // 6. 学習した総日数を計算
        let uniqueStudyDays = Set(allResults.map { Calendar.current.startOfDay(for: $0.date) })
        self.studyDaysCount = uniqueStudyDays.count
        
        // 7. 今日の学習時間を計算
        let today = Date()
        let todayResults = allResults.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        self.todayStudyTime = todayResults.reduce(0) { $0 + $1.duration }
        
        // 8. 連続学習日数（ストリーク）を計算
        let sortedDates = Array(uniqueStudyDays).sorted()
        let streaks = calculateStreaks(from: sortedDates)
        self.currentStreak = streaks.current
        self.longestStreak = streaks.longest
        
        // 9. 週ごとの学習記録を計算
        self.weeklyRecords = calculateWeeklyRecords(from: allResults)
        
        // ★★★ 月間・年間学習時間を計算 ★★★
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        self.monthlyStudyTime = StudyTimeManager.shared.getMonthlyStudyTime(year: currentYear, month: currentMonth)
        self.yearlyStudyTime = StudyTimeManager.shared.getYearlyStudyTime(year: currentYear)

        // ★★★ スキルタグ別・難易度別の分析を計算 ★★★
        var skillTagCounts: [String: (correct: Int, total: Int)] = [:]
        var difficultyCounts: [String: (correct: Int, total: Int)] = [:]

        for result in allResults {
            // QuizResultには正解した問題のIDは含まれていないため、全問題から正解・不正解を判断する
            // ここでは、QuizResultのscoreとtotalQuestions、そしてincorrectQuestionIDsを利用して、
            // 各問題の正誤を判断し、skillTagsとdifficultyLevelに紐付ける
            
            // まず、このresultに含まれる全問題を取得
            guard let quizSet = allCourses.flatMap({ $0.quizSets }).first(where: { $0.setId == result.setId }) else { continue }
            let questionsInQuiz = quizSet.questions
            
            let incorrectQuestionIDsSet = Set(result.incorrectQuestionIDs)
            
            for question in questionsInQuiz {
                let isCorrect = !incorrectQuestionIDsSet.contains(question.id)
                
                // スキルタグ別の集計
                if let tags = question.skillTags {
                    for tag in tags {
                        skillTagCounts[tag, default: (correct: 0, total: 0)].total += 1
                        if isCorrect {
                            skillTagCounts[tag]?.correct += 1
                        }
                    }
                }
                
                // 難易度別の集計
                if let difficulty = question.difficultyLevel {
                    difficultyCounts[difficulty, default: (correct: 0, total: 0)].total += 1
                    if isCorrect {
                        difficultyCounts[difficulty]?.correct += 1
                    }
                }
            }
        }
        
        self.skillTagAnalyses = skillTagCounts.map { (tag, counts) in
            SkillTagAnalysis(id: tag, totalQuestions: counts.total, totalCorrect: counts.correct)
        }.sorted { $0.accuracy > $1.accuracy } // 正答率でソート
        
        self.difficultyAnalyses = difficultyCounts.map { (difficulty, counts) in
            DifficultyAnalysis(id: difficulty, totalQuestions: counts.total, totalCorrect: counts.correct)
        }.sorted { $0.accuracy > $1.accuracy } // 正答率でソート
    }
    
    private func format(duration: TimeInterval) -> String {
        if duration < 1 { return "記録なし" }
        
        if duration < 60 {
            // 60秒未満の場合は、秒数を表示する
            return "\(Int(duration))秒"
        }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        formatter.maximumUnitCount = 2

        return formatter.string(from: duration) ?? "0分"
    }
    
    private func calculateStreaks(from dates: [Date]) -> (current: Int, longest: Int) {
        guard !dates.isEmpty else { return (0, 0) }

        var longestStreak = 0
        var currentStreak = 0
        
        if !dates.isEmpty {
            longestStreak = 1
            currentStreak = 1
        }

        for i in 1..<dates.count {
            let previousDate = dates[i-1]
            let currentDate = dates[i]
            
            if let expectedNextDay = Calendar.current.date(byAdding: .day, value: 1, to: previousDate), expectedNextDay == currentDate {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
            
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        }
        
        if let lastDate = dates.last {
            let today = Date()
            if !Calendar.current.isDateInToday(lastDate) && !Calendar.current.isDateInYesterday(lastDate) {
                 currentStreak = 0
            }
        }

        return (currentStreak, longestStreak)
    }

    // 週の記録を計算するヘルパーメソッド
    private func calculateWeeklyRecords(from allQuizResults: [QuizResult]) -> [DailyStudyRecord] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { return [] }
        let thisWeekResults = allQuizResults.filter { $0.date >= startOfWeek && $0.date < endOfWeek }
        var records: [DailyStudyRecord] = []
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        for i in 0..<7 {
            let dayDate = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            let resultsForDay = thisWeekResults.filter { calendar.isDate($0.date, inSameDayAs: dayDate) }
            let timeForDay = resultsForDay.reduce(0) { $0 + $1.duration }
            let weekdayIndex = calendar.component(.weekday, from: dayDate) - 1
            if weekdayIndex >= 0 && weekdayIndex < weekdays.count {
                records.append(DailyStudyRecord(id: weekdays[weekdayIndex], date: dayDate, studyTime: timeForDay))
            }
        }
        return records
    }
}
