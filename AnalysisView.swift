import SwiftUI
import Charts
import SwiftData

struct AnalysisView: View {
    
    @StateObject private var viewModel = AnalysisViewModel()
    @Query(sort: \QuizResult.date, order: .reverse) private var allQuizResults: [QuizResult]
    @Query(sort: \UnlockedAchievement.dateUnlocked, order: .reverse) private var unlockedAchievements: [UnlockedAchievement]

    // 統計カードを2列で表示するための定義
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // 背景（他の画面と統一感を出すためのオーロラ風エフェクト）
                DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
                Circle().fill(DesignSystem.Colors.CourseAccent.orange.opacity(0.2)).blur(radius: 100).offset(x: -150, y: -200)
                Circle().fill(DesignSystem.Colors.CourseAccent.blue.opacity(0.2)).blur(radius: 120).offset(x: 100, y: 150)

                // メインコンテンツ
                // 学習記録がない場合は、クイズを促すメッセージを表示
                if allQuizResults.isEmpty {
                    emptyStateView
                } else {
                    // 学習記録がある場合は、データを表示
                    mainContentView
                }
            }
            .navigationTitle("学習データ")
            // allQuizResults（学習記録）が変更されるたびに、ViewModelのデータも再計算する
            .onChange(of: allQuizResults, initial: true) {
                Task {
                    await viewModel.calculateAnalytics(with: allQuizResults)
                }
            }
        }
    }
    
    /// 学習記録がある場合に表示されるメインコンテンツ
    private var mainContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // --- 連続学習カード ---
                StreakActivityCard(
                    currentStreak: viewModel.currentStreak,
                    longestStreak: viewModel.longestStreak,
                    weeklyRecords: viewModel.weeklyRecords
                )

                // --- 学習時間・日数セクション ---
                Text("学習時間・日数")
                    .font(.title3.bold())
                
                LazyVGrid(columns: columns, spacing: 16) {
                    DashboardStatCard(title: "学習した日数", value: "\(viewModel.studyDaysCount)", unit: "日", color: .primary)
                    DashboardStatCard(title: "本日の学習時間", value: viewModel.todayStudyTime.toHourMinuteFormat(), unit: "", color: .orange)
                    DashboardStatCard(title: "合計学習時間", value: viewModel.totalStudyTimeFormatted, unit: "", color: .primary)
                }

                // --- 学習数セクション ---
                Text("学習数")
                    .font(.title3.bold())
                
                LazyVGrid(columns: columns, spacing: 16) {
                    DashboardStatCard(title: "累計学習 問題数", value: "\(viewModel.totalQuestionsAnswered)", unit: "問", color: .primary)
                    DashboardStatCard(title: "累計正解数", value: "\(viewModel.totalCorrectAnswers)", unit: "問", color: .green)
                }
                
                // ★★★ 学習履歴への導線 ★★★
                NavigationLink(destination: ResultHistoryView()) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("過去の学習履歴を見る")
                            .font(.headline.bold())
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding()
                    .background(DesignSystem.Colors.surfacePrimary)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                }
                
                // ★★★ 弱点分析セクション ★★★
                if SettingsManager.shared.isPremiumUser && !viewModel.topIncorrectQuestions.isEmpty {
                    Text("あなたの弱点")
                        .font(.title3.bold())
                    
                    VStack(spacing: 10) {
                        ForEach(viewModel.topIncorrectQuestions) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.question.questionText)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text("間違えた回数: \(item.count)回")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(DesignSystem.Colors.surfacePrimary)
                            .cornerRadius(12)
                        }
                    }
                }
                
                // ★★★ 月間・年間学習時間表示セクション ★★★
                Text("これまでの学習記録")
                    .font(.title3.bold())
                
                LazyVGrid(columns: columns, spacing: 16) {
                    DashboardStatCard(title: "今月の学習時間", value: viewModel.monthlyStudyTime.toHourMinuteJapaneseFormat(), unit: "", color: .primary)
                    DashboardStatCard(title: "今年の学習時間", value: viewModel.yearlyStudyTime.toHourMinuteJapaneseFormat(), unit: "", color: .primary)
                }
                
                Text("獲得した実績")
                                    .font(.title3.bold())

                                NavigationLink(destination: AchievementsView()) {
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading) {
                                            Text("獲得済みバッジ")
                                                .font(.headline)
                                                .foregroundColor(.primary)

                                            // 獲得数と総数を表示
                                            Text("\(unlockedAchievements.count) / \(AchievementType.allCases.count) 個")
                                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                                .foregroundColor(.primary)
                                        }

                                        Spacer()

                                        // 最近獲得したバッジのアイコンをプレビュー表示
                                        HStack(spacing: -12) {
                                            ForEach(unlockedAchievements.prefix(3)) { achievement in
                                                if let type = AchievementType(rawValue: achievement.id) {
                                                    Image(systemName: type.unlockedIcon.name)
                                                        .font(.title3)
                                                        .foregroundColor(type.unlockedIcon.color)
                                                        .frame(width: 36, height: 36)
                                                        .background(.regularMaterial)
                                                        .clipShape(Circle())
                                                        .overlay(Circle().stroke(DesignSystem.Colors.backgroundPrimary, lineWidth: 2))
                                                }
                                            }
                                        }

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary.opacity(0.5))
                                    }
                                    .padding()
                                    .background(DesignSystem.Colors.surfacePrimary)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                                }
                
                // --- シェアボタン ---
                Button(action: {
                    // TODO: シェア機能の実装
                }) {
                    Label("学習データをシェアする", systemImage: "square.and.arrow.up")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .tint(.orange) // ボタンの色をオレンジに
                
            }
            .padding()
        }
    }
    
    /// 学習記録がまだない場合に表示されるView
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("学習データがありません")
                .font(.title2.bold())
            Text("クイズに挑戦して、あなたの学習記録をここに表示しましょう。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
