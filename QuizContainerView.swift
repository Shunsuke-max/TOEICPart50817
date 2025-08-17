import SwiftUI

/// カウントダウンとクイズ本体の表示を管理する汎用コンテナView
struct QuizContainerView: View {
    
    private enum Phase {
        case countdown
        case playing
    }
    
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties
    // どちらのクイズタイプにも対応できるように、両方のセットをオプショナルで持つ
    let standardQuizSet: QuizSet?
    let vocabQuizSet: VocabularyQuizSet?
    let vocabAccentColor: Color? // 新しく追加
    
    // StandardQuizViewに渡すための追加情報
    let course: Course?
    let allSetsInCourse: [QuizSet]?
    let timeLimit: Int
    let onQuizCompleted: (() -> Void)? // 新しく追加

    // 状態管理
    @State private var phase: Phase = .countdown
    @State private var countdownNumber: Int = 3
    @State private var animateCountdown = false

    // 新しく追加するプロパティ
    @State private var loadedQuizSet: QuizSet?
    @State private var isLoading: Bool = true
    @State private var quizSetId: String?
    @State private var loadedCourse: Course? // 追加
    let quizDisplayMode: QuizDisplayMode // 新しく追加
    
    // MARK: - Initializers
    
    

    // 通常クイズ用のinit
    init(quizSet: QuizSet, course: Course?, allSetsInCourse: [QuizSet]?, timeLimit: Int, vocabAccentColor: Color? = nil, quizDisplayMode: QuizDisplayMode = .standard) {
        self.standardQuizSet = quizSet
        self.vocabQuizSet = nil
        self.vocabAccentColor = vocabAccentColor
        self.course = course
        self.allSetsInCourse = allSetsInCourse
        self.timeLimit = timeLimit
        self.onQuizCompleted = nil
        self.quizDisplayMode = quizDisplayMode // ここを追加
        _loadedQuizSet = State(initialValue: quizSet)
        _isLoading = State(initialValue: false)
        _quizSetId = State(initialValue: nil)
        _loadedCourse = State(initialValue: course)
    }

    // ★★★ 単語レッスン用の新しいinit ★★★
    init(vocabSet: VocabularyQuizSet, onQuizCompleted: (() -> Void)?, vocabAccentColor: Color, quizDisplayMode: QuizDisplayMode = .standard) {
        self.standardQuizSet = nil
        self.vocabQuizSet = vocabSet
        self.vocabAccentColor = vocabAccentColor
        self.course = nil
        self.allSetsInCourse = nil
        self.timeLimit = 0
        self.onQuizCompleted = onQuizCompleted
        self.quizDisplayMode = quizDisplayMode // ここを追加
        _loadedQuizSet = State(initialValue: nil)
        _isLoading = State(initialValue: false)
        _quizSetId = State(initialValue: nil)
        _loadedCourse = State(initialValue: nil as Course?)
    }

    // ★★★ quizSetIdを受け取る新しいinit ★★★
    init(quizSetId: String, quizDisplayMode: QuizDisplayMode = .standard) {
        self.standardQuizSet = nil
        self.vocabQuizSet = nil
        self.vocabAccentColor = nil
        self.course = nil
        self.allSetsInCourse = nil
        self.timeLimit = 0
        self.onQuizCompleted = nil
        self.quizDisplayMode = quizDisplayMode // ここを追加
        _loadedQuizSet = State(initialValue: nil)
        _isLoading = State(initialValue: true)
        _quizSetId = State(initialValue: quizSetId)
        _loadedCourse = State(initialValue: nil as Course?) // 初期値はnil
    }

    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 背景色は、vocabAccentColorがあればそれを使用、なければデフォルト
            AuroraBackgroundView(colors: [vocabAccentColor ?? loadedCourse?.courseColor ?? DesignSystem.Colors.backgroundPrimary, DesignSystem.Colors.backgroundPrimary])

            if isLoading {
                ProgressView("Loading Quiz...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .foregroundColor(.white)
            } else {
                switch phase {
                case .countdown:
                    countdownView
                case .playing:
                    // ★★★ どのクイズViewを表示するかをここで決定 ★★★
                    destinationQuizView()
                }
            }
        }
        .onAppear(perform: startCountdown)
        .navigationBarHidden(true) // 常にナビゲーションバーを隠し、各クイズViewに表示を委ねる
        .toolbar(.hidden, for: .tabBar) // クイズ中はタブバーを非表示にする
        .task {
            if let id = quizSetId, loadedQuizSet == nil {
                do {
                    loadedQuizSet = try await DataService.shared.getQuizSet(byId: id)
                    // quizSetIdからCourseを特定
                    let allCourses = try await DataService.shared.loadAllCoursesWithDetails()
                    loadedCourse = allCourses.first { course in
                        course.quizSets.contains { $0.setId == id }
                    }
                    isLoading = false
                } catch {
                    print("Failed to load quiz set or course: \(error)")
                    isLoading = false
                    // Handle error, maybe show an alert
                }
            }
        }
    }
    
    // MARK: - Destination View
    
    @ViewBuilder
    private func destinationQuizView() -> some View {
        // vocabQuizSetが渡されていれば、単語レッスン画面を表示
        if let vocabSet = vocabQuizSet {
            VocabularyLessonQuizView(vocabSet: vocabSet, onQuizCompleted: onQuizCompleted, accentColor: vocabAccentColor ?? DesignSystem.Colors.brandPrimary) // デフォルト色を設定
        }
        // standardQuizSetが渡されていれば、通常のクイズ画面を表示
        else if let quizSet = standardQuizSet ?? loadedQuizSet { // Use loadedQuizSet if standardQuizSet is nil
            StandardQuizView(
                quizSet: quizSet,
                course: loadedCourse, // loadedCourseを渡す
                allSetsInCourse: allSetsInCourse,
                timeLimit: timeLimit,
                quizDisplayMode: quizDisplayMode // ここを追加
            )
        }
    }
    
    // MARK: - Countdown UI (変更なし)
    
    @ViewBuilder
    private var countdownView: some View {
        Text(countdownNumber > 0 ? "\(countdownNumber)" : "START!")
            .font(.system(size: 90, weight: .black, design: .rounded))
            .foregroundColor(.white) // 文字色を白に変更
            .padding(.horizontal, 30) // 横方向のパディング
            .padding(.vertical, 15) // 縦方向のパディング
            .background(RoundedRectangle(cornerRadius: 25).fill(Color.black.opacity(0.4))) // 丸みを帯びた長方形背景
            .scaleEffect(animateCountdown ? 1.0 : 1.5)
            .opacity(animateCountdown ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animateCountdown = true
                }
            }
            .id(countdownNumber)
    }
    
    // MARK: - Logic (変更なし)
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard self.phase == .countdown else {
                timer.invalidate()
                return
            }
            
            if self.countdownNumber > 0 {
                self.countdownNumber -= 1
                self.animateCountdown = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        self.animateCountdown = true
                    }
                }
                // SoundManager.shared.playSound(named: "countdown.wav") // ファイルが存在しないためコメントアウト
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        self.phase = .playing
                    }
                }
                // SoundManager.shared.playSound(named: "start.wav") // ファイルが存在しないためコメントアウト
            }
        }
    }
}
