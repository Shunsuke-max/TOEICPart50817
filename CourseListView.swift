import SwiftUI
import SwiftData

struct CourseListView: View {
    let courses: [Course]
    
    @Query(sort: \QuizResult.date, order: .reverse) private var allResults: [QuizResult]
    
    @State private var hasPerformedInitialScroll = false
    @State private var showUsageSheet = false // Added this line

    // MARK: - Computed Properties
    private var skillCourses: [Course] {
        courses.filter { $0.courseId.contains("BASIC") || $0.courseId.contains("BIZ_VOCAB") }
    }
    private var levelCourses: [Course] {
        courses.filter { $0.courseId.contains("SCORE") }.sorted { $0.courseId < $1.courseId }
    }
    private let skillColumns: [GridItem] = [GridItem(.flexible())] // Single column
    private let courseColumns: [GridItem] = [GridItem(.flexible())] // Single column

    private var expertCourses: [Course] {
        courses.filter { $0.courseId.contains("EXPERT") }
    }

    private var recommendedCourse: Course? {
        courses.first(where: { $0.isRecommended == true })
    }

    private var groupedLevelCourses: [(String, [Course])] {
        let grouped = Dictionary(grouping: levelCourses) { course in
            if let scoreString = course.courseId.split(separator: "_").last {
                return String(scoreString)
            }
            return "その他" // Fallback for courses not matching the pattern
        }

        let sortedKeys = grouped.keys.sorted { (s1, s2) -> Bool in
            if let score1 = Int(s1), let score2 = Int(s2) {
                return score1 < score2
            }
            return s1 < s2 // Fallback for non-numeric keys
        }

        return sortedKeys.map { key in
            (key, grouped[key] ?? [])
        }
    }

    private var auroraColors: [Color] {
        if let recommendedColor = recommendedCourse?.courseColor {
            return [recommendedColor.opacity(0.8), recommendedColor.opacity(0.5), DesignSystem.Colors.brandPrimary.opacity(0.6)]
        } else {
            return [
                DesignSystem.Colors.CourseAccent.green.opacity(0.8),
                DesignSystem.Colors.CourseAccent.blue.opacity(0.6)
            ]
        }
    }

    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: auroraColors)
            .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        if let recommended = recommendedCourse {
                            recommendedSection(for: recommended)
                        }
                        levelRoadmapSection(showUsageSheet: $showUsageSheet)
                        // skillSection(showUsageSheet: $showUsageSheet) // 基礎スキルを固めるコースを非表示
                        // if !expertCourses.isEmpty {
                        //     expertSection(showUsageSheet: $showUsageSheet) // エキスパート向け特訓コースを非表示
                        // }
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    if !hasPerformedInitialScroll, let recommendedId = recommendedCourse?.id {
                        withAnimation {
                            proxy.scrollTo(recommendedId, anchor: .center)
                        }
                        hasPerformedInitialScroll = true
                    }
                }
            }
            .navigationTitle("コース一覧")
        }
    }

    // MARK: - Child Sections

    @ViewBuilder
    func recommendedSection(for course: Course) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("あなたへのおすすめ")
                .font(.title2.bold())
                .padding(.horizontal)

            NavigationLink(destination: QuizSetSelectionView(course: course).toolbar(.hidden, for: .tabBar)) {
                Group {
                    CourseCardView(course: course, isLocked: !isCourseUnlocked(course: course), isRecommended: true)
                }
            }
            .buttonStyle(TrainingCardButtonStyle())
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func expertSection(showUsageSheet: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("エキスパート向け特訓コース")
                    .font(.title2.bold())
                Button(action: { showUsageSheet.wrappedValue = true }) {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                ForEach(expertCourses) { course in
                    NavigationLink(destination: QuizSetSelectionView(course: course).toolbar(.hidden, for: .tabBar)) {
                        CourseCardView(course: course, isLocked: !self.isCourseUnlocked(course: course))
                    }
                    .buttonStyle(TrainingCardButtonStyle())
                    .disabled(!isCourseUnlocked(course: course))
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func skillSection(showUsageSheet: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("基礎スキルを固める")
                    .font(.title2.bold())
                Button(action: { showUsageSheet.wrappedValue = true }) {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 16) { // Changed from LazyVGrid
                ForEach(skillCourses) { course in
                    NavigationLink(destination: QuizSetSelectionView(course: course).toolbar(.hidden, for: .tabBar)) {
                        CourseCardView(course: course, isLocked: !self.isCourseUnlocked(course: course))
                    }
                    .buttonStyle(TrainingCardButtonStyle())
                    .disabled(!isCourseUnlocked(course: course))
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func levelRoadmapSection(showUsageSheet: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("スコア別 対策コース")
                    .font(.title2.bold())
                Button(action: { showUsageSheet.wrappedValue = true }) {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            ForEach(groupedLevelCourses, id: \.0) { scoreLevel, coursesInLevel in
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(scoreLevel)点目標")
                        .font(.headline.bold())
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ForEach(Array(coursesInLevel.enumerated()), id: \.element.id) { index, course in
                        let isRecommended = (course.id == recommendedCourse?.id)
                    let isAchieved = calculateProgress(for: course) >= 1.0
                    let isLocked = !isCourseUnlocked(course: course)

                        NavigationLink(destination: QuizSetSelectionView(course: course).toolbar(.hidden, for: .tabBar)) {
                            roadmapCard(
                                for: course,
                                index: index,
                                isRecommended: isRecommended,
                                isAchieved: isAchieved,
                                isLocked: isLocked
                            )
                        }
                        .buttonStyle(TrainingCardButtonStyle())
                        .id(course.id)
                        .disabled(isLocked)
                    }
                }
            }
        }
    }

    // MARK: - Reusable Views

    /// ロードマップの各カードを生成する
    @ViewBuilder
    func roadmapCard(for course: Course, index: Int, isRecommended: Bool, isAchieved: Bool, isLocked: Bool) -> some View {
        let progress = isAchieved ? 1.0 : calculateProgress(for: course)

        HStack(spacing: -25) {
            roadmapCardIcon(for: course, index: index, isLocked: isLocked, isAchieved: isAchieved)
            roadmapCardDetails(for: course, isRecommended: isRecommended, isLocked: isLocked, isAchieved: isAchieved, progress: progress)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    func roadmapCardIcon(for course: Course, index: Int, isLocked: Bool, isAchieved: Bool) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(index == 0 ? Color.clear : (isLocked ? Color.gray.opacity(0.2) : Color.gray.opacity(0.4)))
                .frame(width: 3, height: 20)

            ZStack {
                Image(systemName: isLocked ? "lock.fill" : course.courseIcon)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(isLocked ? AnyShapeStyle(Color.gray.opacity(0.5)) : AnyShapeStyle(course.courseColor.gradient))
                    .clipShape(Circle())

                if isAchieved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.green)
                        .clipShape(Circle())
                        .offset(x: 20, y: -20)
                }
            }

            Rectangle()
                .fill(index == levelCourses.count - 1 ? Color.clear : (isLocked ? Color.gray.opacity(0.2) : Color.gray.opacity(0.4)))
                .frame(width: 3, height: 20)
        }
        .zIndex(1)
    }

    @ViewBuilder
    func roadmapCardDetails(for course: Course, isRecommended: Bool, isLocked: Bool, isAchieved: Bool, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            roadmapCardHeader(for: course, isRecommended: isRecommended, isLocked: isLocked)
            roadmapCardInfo(for: course, isLocked: isLocked)
            roadmapCardTags(for: course, isLocked: isLocked)
            roadmapCardProgress(progress: progress, isAchieved: isAchieved, isLocked: isLocked, course: course)
        }
        .padding([.vertical, .trailing])
        .padding(.leading, 50)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isLocked ? AnyShapeStyle(DesignSystem.Colors.surfacePrimary.opacity(0.5)) : AnyShapeStyle(DesignSystem.Colors.surfacePrimary.opacity(0.9).gradient))
        .cornerRadius(12)
        .shadow(color: isRecommended ? .pink.opacity(0.5) : .clear, radius: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isLocked ? Color.gray.opacity(0.3) : course.courseColor.opacity(0.5), lineWidth: 1)
        )
    }

    @ViewBuilder
    func roadmapCardHeader(for course: Course, isRecommended: Bool, isLocked: Bool) -> some View {
        HStack {
            Text(course.courseName)
                .font(.headline.bold())
                .foregroundColor(isLocked ? .gray : .primary)
            Spacer()
            if isRecommended {
                Text("おすすめ")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pink.gradient)
                    .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    func roadmapCardInfo(for course: Course, isLocked: Bool) -> some View {
        if let totalLessons = course.totalLessons {
            Text("全 \(totalLessons) レッスン")
                .font(.caption)
                .foregroundColor(isLocked ? .gray : .secondary)
        } else {
            Text(course.courseDescription)
                .font(.caption)
                .foregroundColor(isLocked ? .gray : .secondary)
                .lineLimit(2)
        }
        if let estimatedTime = course.estimatedStudyTime {
            Text("推定学習時間: 約\(estimatedTime)分")
                .font(.caption)
                .foregroundColor(isLocked ? .gray : .secondary)
        }
    }

    @ViewBuilder
    func roadmapCardTags(for course: Course, isLocked: Bool) -> some View {
        if let tags = course.learningTags, !tags.isEmpty {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isLocked ? Color.gray.opacity(0.1) : course.courseColor.opacity(0.2))
                        .cornerRadius(5)
                }
            }
        }
    }

    @ViewBuilder
    func roadmapCardProgress(progress: Double, isAchieved: Bool, isLocked: Bool, course: Course) -> some View {
        VStack(alignment: .leading) {
            ProgressView(value: progress)
                .tint(isAchieved ? .green : (isLocked ? .gray : course.courseColor))
                .frame(height: 8)
            Text(String(format: "%.0f%%", progress * 100))
                .font(.caption.bold())
                .foregroundColor(isAchieved ? .green : (isLocked ? .gray : course.courseColor))
        }
    }

    // MARK: - Helper Methods

    private func isCourseUnlocked(course: Course) -> Bool {
        // Proユーザーは常に全てのコースがアンロック
        if SettingsManager.shared.isPremiumUser {
            return true
        }

        // 無料ユーザーの場合、特定のコースのみをアンロック
        let freeCourses: Set<String> = ["BASIC_GRAMMAR", "BASIC_VOCAB"]
        if freeCourses.contains(course.courseId) {
            return true
        }

        // それ以外のコースは、アンロック条件に従う
        guard let unlockCondition = course.unlockCondition else {
            return true // No unlock condition, so it's unlocked by default
        }

        // Example unlock conditions: "SCORE_600_COMPLETED", "BASIC_GRAMMAR_COMPLETED"
        let components = unlockCondition.split(separator: "_")
        guard components.count == 2, let courseId = components.first else {
            return true // Malformed condition, treat as unlocked
        }

        let prerequisiteCourseId = String(courseId)

        // Check if the prerequisite course is completed
        let prerequisiteCourse = courses.first(where: { $0.courseId == prerequisiteCourseId })
        guard let prereq = prerequisiteCourse else {
            return true // Prerequisite course not found, treat as unlocked
        }

        let progress = calculateProgress(for: prereq)
        return progress >= 0.7 // Assuming 70% completion to unlock
    }

    func calculateProgress(for course: Course) -> Double {
        let requiredAccuracy = 0.8 // 80%以上の正解率

        // 1. 通常のクイズセットの進捗を計算
        let regularQuizSets = course.quizSets.filter { !$0.setId.hasSuffix("_ACHIEVEMENT_TEST") } // 達成度テストを除外
        let completedRegularSets = regularQuizSets.filter { set in
            allResults.contains(where: { $0.setId == set.setId && Double($0.score) / Double($0.totalQuestions) >= requiredAccuracy })
        }.count

        // 2. 達成度テストの進捗を計算
        let achievementTestSetId = "\(course.id)_ACHIEVEMENT_TEST"
        print("DEBUG: calculateProgress achievementTestSetId: \(achievementTestSetId)")
        let achievementTestCompleted = allResults.contains(where: { $0.setId == achievementTestSetId && Double($0.score) / Double($0.totalQuestions) >= requiredAccuracy })
        // 3. 全体の進捗を合算して計算
        var totalSetsToConsider = regularQuizSets.count
        if achievementTestSetId != "" { // 達成度テストが存在する場合
            totalSetsToConsider += 1
        }

        guard totalSetsToConsider > 0 else { return 0.0 }

        var totalCompletedCount = completedRegularSets
        if achievementTestCompleted {
            totalCompletedCount += 1
        }

        return Double(totalCompletedCount) / Double(totalSetsToConsider)
    }
}
