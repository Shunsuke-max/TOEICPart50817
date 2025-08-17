import SwiftUI
import Combine
import SwiftData

@MainActor
class HomeViewModel: ObservableObject {
    
    enum ReviewState {
        case available(count: Int) // 復習可能（件数付き）
        case completedToday // 今日すでに完了済み
        case nothingToReview // 復習対象がそもそもない
    }
    
    // MARK: - Published Properties
    @Published var reviewState: ReviewState = .nothingToReview
    @Published var totalStudyTime: TimeInterval = 0
    @Published var dailyGoal: TimeInterval = SettingsManager.shared.dailyGoal
    @Published var todaysProgress: TimeInterval = 0
    @Published var weeklyDailyRecords: [DailyStudyRecord] = []
    @Published var monthlyStudyTime: TimeInterval = 0
    @Published var yearlyStudyTime: TimeInterval = 0
    
    @Published var streakCount: Int = 0
    @Published var longestStreakCount: Int = 0
    
    @Published var recommendedCourse: Course?
    
    @Published var userLevel: Int = 1
    @Published var currentXP: Int = 0
    @Published var xpForNextLevel: Int = 100
    @Published var toeicScoreEstimate: String = ""
    
    @Published var predictedPart5Score: Int = 0
    
    // アニメーション用の状態
    @Published var streakNumberScale: CGFloat = 1.0
    @Published var showMilestoneView = false
    @Published var achievedMilestone: (days: Int, message: String)?
    @Published var showGoalAchievedView = false
    
    private var hasShownGoalViewToday = false
    private var modelContext: ModelContext?

    private var cancellables = Set<AnyCancellable>()
    private var reviewManager: ReviewManager
    
    init() {
        self.reviewManager = ReviewManager()
        // 各Managerからの通知を監視する
        UserStatsManager.shared.statsChanged.sink { [weak self] in
            // 🚨 NOTE: The original error on this line was a symptom of the larger brace issue.
            // With the structure fixed, this call will now correctly find the updateUserStats method.
            self?.updateUserStats()
        }.store(in: &cancellables)
        
        
    }

    // MARK: - Logic Methods
    
    func setup(context: ModelContext) {
        self.modelContext = context
    }
    
    func updateAllStats(quizResults: [QuizResult]) async {
        // 1. まずXPを即時更新
        updateUserStats()
        
        // 2. 次に学習時間を計算
        self.totalStudyTime = StudyTimeManager.shared.getTotalStudyTime()
        self.dailyGoal = SettingsManager.shared.dailyGoal
        
        let calendar = Calendar.current
        let todaysResults = quizResults.filter { calendar.isDateInToday($0.date) }
        let newProgress = todaysResults.reduce(0) { $0 + $1.duration }
        
        // 3. 少し遅れて円グラフを更新し、因果関係を視覚的に示す
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            
            await MainActor.run {
                if newProgress > self.todaysProgress {
                    if newProgress >= self.dailyGoal && self.dailyGoal > 0 && !hasShownGoalViewToday {
                        self.showGoalAchievedView = true
                        self.hasShownGoalViewToday = true
                    }
                }
                self.todaysProgress = newProgress
                
                if dailyGoal > 0 && todaysProgress >= dailyGoal {
                    if let context = modelContext {
                        AchievementManager.logDailyGoalAchieved(context: context)
                    }
                }
            }
        }
        
        // 4. その他のUIは即時更新
        updateWeeklyRecords(allQuizResults: quizResults)
        await updateReviewState()
        
        // ‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
        //  HERE is the missing closing brace that caused all the errors.
        // ‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️‼️
    }
    
    func fetchRecommendation() async {
        guard !SettingsManager.shared.hasSeenInitialRecommendation, self.recommendedCourse == nil, let context = modelContext else {
            return
        }
        self.recommendedCourse = await RecommendationManager.generateRecommendation(context: context)
    }
    
    
    // MARK: - Private Helper Methods
    
    private func updateWeeklyRecords(allQuizResults: [QuizResult]) {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { return }
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
        self.weeklyDailyRecords = records
    }
    
    private func updateUserStats() {
        // XPとレベルの更新ロジックはUserStatsManagerに任せる
        // TOEICスコア推定は予測スコアに置き換わるため、ここでは更新しない
    }
    
    private func triggerStreakAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
            streakNumberScale = 1.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                self.streakNumberScale = 1.0
            }
        }
    }
    
    private func checkMilestone(for newStreak: Int) {
        if let milestone = MilestoneManager.shared.checkAndAwardMilestone(for: newStreak) {
            self.achievedMilestone = milestone
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showMilestoneView = true
            }
        }
    }
    
    private func updateReviewState() async {
        guard let context = modelContext else { return }
        
        if let lastCompletion = SettingsManager.shared.lastReviewSessionDate,
           Calendar.current.isDateInToday(lastCompletion) {
            self.reviewState = .completedToday
            return
        }
        
        let count = await reviewManager.getTodaysReviewCount(modelContext: context)
        if count > 0 {
            self.reviewState = .available(count: count)
        } else {
            self.reviewState = .nothingToReview
        }
    }
    
    private func calculatePredictedScore(from quizResults: [QuizResult]) {
        let part5Results = quizResults.filter { $0.setId.hasPrefix("SCORE_") || $0.setId.hasPrefix("BASIC_") || $0.setId.hasPrefix("BIZ_") || $0.setId.hasPrefix("VOCAB_") }
            .sorted { $0.date > $1.date }
            .prefix(100)
        
        guard !part5Results.isEmpty else {
            self.predictedPart5Score = 0
            return
        }
        
        var totalCorrect = 0
        var totalQuestions = 0
        
        for result in part5Results {
            totalCorrect += result.score
            totalQuestions += result.totalQuestions
        }
        
        guard totalQuestions > 0 else {
            self.predictedPart5Score = 0
            return
        }
        
        let accuracy = Double(totalCorrect) / Double(totalQuestions)
        
        let minScore = 20
        let maxScore = 150
        
        let estimatedScore = minScore + Int(accuracy * Double(maxScore - minScore))
        
        self.predictedPart5Score = estimatedScore
    }
}

// This extension is now correctly at the "file scope" (outside the class definition).
extension HomeViewModel.ReviewState {
    var isUnavailable: Bool {
        switch self {
        case .available:
            return false
        case .completedToday, .nothingToReview:
            return true
        }
    }
    
    var subtitle: String {
        switch self {
        case .available(let count):
            return "\(count) 問の復習問題があります"
        case .completedToday:
            return "今日の復習は完了しました"
        case .nothingToReview:
            return "復習する問題はありません"
        }
    }
}
