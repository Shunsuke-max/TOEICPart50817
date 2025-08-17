import SwiftUI
import SwiftData

struct QuizSetSelectionView: View {
    @StateObject private var viewModel = QuizSetSelectionViewModel()
    
    let course: Course
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    init(course: Course) {
        self.course = course
    }
    
    var body: some View {
        ZStack {
            course.courseColor.opacity(0.1).ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("コースデータを準備中...")
            } else if let error = viewModel.error {
                Text("エラー: \(error.localizedDescription)")
            } else {
                contentView
            }
        }
        .task {
            await viewModel.loadData(for: course, context: modelContext)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.secondary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(course.courseName)
                    .font(.headline.bold())
            }
        }
    }
    
    // MARK: - Main Content View
    @ViewBuilder
    private var contentView: some View {
        if viewModel.quizSets.isEmpty && viewModel.vocabQuizSets.isEmpty {
            Text("このコースには問題セットがありません。")
        } else {
            ScrollView {
                        VStack(alignment: .leading, spacing: 0) { // ★ spacingを0に
                            
                            step1Section
                                .padding(.bottom, 32) // ★ STEP1の下に大きな余白を追加

                            // ★ オプション：区切り線を追加すると、さらに分かりやすくなります
                            Divider().padding(.horizontal)
                            
                            step2Section
                                .padding(.top, 32) // ★ STEP2の上に大きな余白を追加
                                .padding(.bottom, 32) // ★ STEP2の下に大きな余白を追加

                            // ★ オプション：区切り線
                            Divider().padding(.horizontal)

                            step3Section
                                .padding(.top, 32) // ★ STEP3の上に大きな余白を追加
                            
                        }
                        .padding()
                    }
                }
            }
    
    // MARK: - Child Sections
    
    /// STEP 1: 語彙力強化セクション
    @ViewBuilder
        private var step1Section: some View {
            StepSectionView(step: 1, title: "頻出単語をマスターしよう", status: viewModel.step1Status, isFirstStep: true, isLastStep: false) {
                if let vocabInfo = viewModel.findMatchingVocabLevel(for: course) {
                    NavigationLink(destination: VocabularyQuizSetSelectionView(
                        levelName: vocabInfo.level,
                        vocabJsonFileName: vocabInfo.jsonFileName,
                        color: vocabInfo.color
                    )) {
                        LinkCardView(
                            title: "\(vocabInfo.level) 単語レッスン",
                            icon: "graduationcap.fill",
                            color: vocabInfo.color
                        )
                    }
                }
            }
        }
    
    /// STEP 2: 実践問題セクション
    @ViewBuilder
    private var step2Section: some View {
        StepSectionView(step: 2, title: "実践問題に挑戦しよう", status: viewModel.step2Status, lockMessage: "STEP 1の全ての単語クイズで80%以上正解すると解放されます。", isFirstStep: false, isLastStep: false)
        {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.quizSets) { quizSet in
                    NavigationLink(destination: QuizStartPromptView(quizSet: quizSet, course: course, allSetsInCourse: viewModel.quizSets)) {
                        let progress = viewModel.progressForSets[quizSet.id] ?? 0.0
                        gridItem(for: quizSet, progress: progress, isLocked: viewModel.step2Status.isLocked)
                    }
                }
            }
        }
    }
    
    /// STEP 3: コース達成度テストセクション
    @ViewBuilder
    private var step3Section: some View {
        StepSectionView(step: 3, title: "コース達成度テスト", status: viewModel.step3Status, lockMessage: "STEP 1と2の全ての問題で80%以上正解すると解放されます。", isFirstStep: false, isLastStep: true)
        {
            if let achievementTestSet = viewModel.achievementTestQuizSet {
                NavigationLink(destination: QuizStartPromptView(specialQuizSet: achievementTestSet, course: course)) {
                    LinkCardView(title: "模擬テスト (\(achievementTestSet.questions.count)問)", icon: "rosette", color: Color.yellow)
                }
            } else {
                ProgressView()
            }
        }
    }
    
    // MARK: - Reusable Grid Item
    
    /// グリッドアイテムの見た目を生成する
    @ViewBuilder
    private func gridItem(for quizSet: QuizSet, progress: Double, isLocked: Bool) -> some View {
        let isPerfect = progress >= 1.0
        
        VStack(spacing: 12) {
            ZStack {
                Circle().stroke(lineWidth: 8).opacity(0.15).foregroundColor(course.courseColor)
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundColor(isPerfect ? .yellow : course.courseColor)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.easeInOut, value: progress)
                Image(systemName: "text.book.closed.fill")
                    .font(.title)
                    .foregroundColor(isLocked ? .secondary.opacity(0.8) : course.courseColor)
                if isPerfect {
                    VStack { Spacer(); HStack { Spacer(); Image(systemName: "crown.fill").foregroundColor(.yellow).font(.body).padding(5).background(Circle().fill(.black.opacity(0.6))).offset(x: 4, y: 4) } }
                }
            }
            .frame(width: 80, height: 80)
            
            VStack {
                Text(quizSet.setName).font(.headline).fontWeight(.bold).foregroundColor(.primary).lineLimit(1)
                
                if progress > 0 {
                    let score = Int(progress * Double(quizSet.questions.count))
                    Text("最高: \(score)/\(quizSet.questions.count)").font(.caption).fontWeight(.semibold).foregroundColor(isPerfect ? .yellow : course.courseColor)
                } else {
                    Text("\(quizSet.questions.count) 問").font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity).padding().background(Color(.systemBackground)).cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 3).opacity(isLocked ? 0.6 : 1.0)
    }
    
    // MARK: - Child Views
    
    private struct StepSectionView<Content: View>: View {
        let step: Int
        let title: String
        let status: (isComplete: Bool, isLocked: Bool)
        var lockMessage: String? = nil
        let isFirstStep: Bool
        let isLastStep: Bool
        @ViewBuilder let content: Content
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                timelineView
                
                VStack(alignment: .leading, spacing: 16) {
                    StepHeaderView(step: step, title: title, isComplete: status.isComplete)
                    
                    content
                        .opacity(status.isLocked ? 0.6 : 1.0)
                        .disabled(status.isLocked)
                        .overlay {
                            if status.isLocked {
                                Color.black.opacity(0.1).cornerRadius(12)
                                    .overlay(Image(systemName: "lock.fill").foregroundColor(.white).font(.title))
                            }
                        }
                    
                    if status.isLocked, let message = lockMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                            Text(message)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .transition(.opacity.animation(.easeInOut))
                    }
                }
            }
        }
        
        @ViewBuilder
        private var timelineView: some View {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirstStep ? Color.clear : (status.isComplete ? Color.green : Color.gray.opacity(0.3)))
                    .frame(width: 3, height: 20)
                
                ZStack {
                    Circle().fill(status.isComplete ? Color.green : (status.isLocked ? Color.gray.opacity(0.5) : Color.secondary))
                    if status.isComplete {
                        Image(systemName: "checkmark").foregroundColor(.white).bold()
                    } else {
                        Text("\(step)").font(.subheadline.bold()).foregroundColor(.white)
                    }
                }
                .frame(width: 30, height: 30)
                
                Rectangle()
                    .fill(isLastStep ? Color.clear : Color.gray.opacity(0.3))
                    .frame(width: 3)
            }
        }
    }
    
    private struct StepHeaderView: View {
        let step: Int
        let title: String
        let isComplete: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline.bold()).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(Color.green))
                } else {
                    Text("STEP \(step)")
                        .font(.headline.bold()).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 4)
                        .background(Capsule().fill(Color.secondary))
                }
                Text(title).font(.title3.bold())
            }
        }
    }
    
    private struct LinkCardView: View {
        let title: String
        let icon: String
        let color: Color
        
        var body: some View {
            HStack {
                Image(systemName: icon).font(.title3).foregroundColor(color).frame(width: 30)
                Text(title).font(.headline).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary.opacity(0.5))
            }
            .padding().background(DesignSystem.Colors.surfacePrimary).cornerRadius(12)
        }
    }
}
