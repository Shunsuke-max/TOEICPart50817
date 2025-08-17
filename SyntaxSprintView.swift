import SwiftUI
import SwiftData

struct SyntaxSprintView: View {
    private static let hasSeenSyntaxSprintInfoKey = "hasSeenSyntaxSprintInfo"
    @StateObject private var viewModel: SyntaxSprintViewModel
    
    // ★★★ 戻る機能のためのプロパティを追加 ★★★
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var isShowingExitAlert = false
    
    // フィードバック演出用のState
    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .green
    @State private var showFeedback: Bool = false
    
    // UI状態を管理するState
    @State private var showInitialInfoSheet: Bool = true
    @State private var initialLoading: Bool = false
    @State private var showCountdown: Bool = false
    @State private var gameStarted: Bool = false
    @State private var assembledChunks: [Chunk] = [] // ScramblePuzzleViewと共有するチャンクの状態

    init(difficulty: Int, skills: [String], genres: [String]) {
        _viewModel = StateObject(wrappedValue: SyntaxSprintViewModel(difficulty: difficulty, skills: skills, genres: genres))
    }

    var body: some View {
        return ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            
            if initialLoading {
                ProgressView("Ready...")
            } else if showCountdown {
                CountdownView(onFinished: {
                    print("DEBUG: Countdown finished. Calling viewModel.startGame()...")
                    showCountdown = false
                    viewModel.startGame()
                })
            } else if viewModel.isGameOver {
                SyntaxSprintResultView(viewModel: viewModel, showCountdown: $showCountdown)
            } else {
                gameplayView(viewModel: viewModel, feedbackText: $feedbackText, feedbackColor: $feedbackColor, showFeedback: $showFeedback)
            }
        }
        .onAppear {
            assembledChunks = [] // 画面表示時にチャンクをリセット
        }
        .onChange(of: viewModel.currentQuestion) {
            assembledChunks = [] // 新しい問題がロードされたときにチャンクをリセット
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .navigationTitle("並び替えスプリント")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // ゲームプレイが開始されてから中断アラートを出す
                    if !initialLoading && !showCountdown {
                        isShowingExitAlert = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .disabled(initialLoading || showCountdown) // ロード中またはカウントダウン中はボタンを無効化
                .opacity(initialLoading || showCountdown ? 0 : 1) // ロード中またはカウントダウン中はボタンを非表示
            }
        }
        .alert("ゲームを中断しますか？", isPresented: $isShowingExitAlert) {
            Button("中断する", role: .destructive) {
                viewModel.endGame()
                dismiss()
            }
            Button("続ける", role: .cancel) {}
        } message: {
            Text("現在のスコアやコンボは保存されません。")
        }
        .sheet(isPresented: $showInitialInfoSheet, onDismiss: {
            if !gameStarted {
                dismiss() // Dismiss SyntaxSprintView itself
            }
            UserDefaults.standard.set(true, forKey: SyntaxSprintView.hasSeenSyntaxSprintInfoKey) // Set flag when sheet is dismissed
        }) {
            SyntaxSprintInfoSheet(
                onStartGame: {
                    print("DEBUG: SyntaxSprintInfoSheet onStartGame triggered.")
                    showInitialInfoSheet = false
                    initialLoading = true // ゲーム準備開始時にロード表示を有効にする
                    gameStarted = true // Mark game as started
                    Task { @MainActor in
                        print("DEBUG: Calling viewModel.prepareGame()...")
                        await viewModel.prepareGame()
                        print("DEBUG: viewModel.prepareGame() finished. Setting initialLoading to false and showCountdown to true.")
                        initialLoading = false
                        showCountdown = true
                    }
                },
                initialTime: SyntaxSprintViewModel.initialTime
            )
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    // ゲームプレイ中のUI
    private func gameplayView(viewModel: SyntaxSprintViewModel, feedbackText: Binding<String>, feedbackColor: Binding<Color>, showFeedback: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            StatusBarView(viewModel: viewModel)
                .padding()

            if let question = viewModel.currentQuestion {
                VStack(spacing: 10) {
                    // 問題文（日本語訳）
                    Text(question.questionText)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    ScramblePuzzleView(viewModel: viewModel, question: question, onAnswerSubmit: { chunks in handleAnswerSubmit(assembledChunks: chunks) }, assembledChunks: $assembledChunks)

                    // 「答えを確認する」ボタン
                    Button(action: {
                        handleAnswerSubmit(assembledChunks: assembledChunks)
                    }) {
                        Text("答えを確認する")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Colors.brandPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    HStack {
                        Button(action: { viewModel.applyHint(type: .firstChunk) }) {
                            Label("最初のチャンク", systemImage: "lightbulb.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(DesignSystem.Colors.textSecondary.opacity(0.2))) // 色を調整
                                .foregroundColor(DesignSystem.Colors.textSecondary) // 色を調整
                        }
                        .buttonStyle(.plain)

                        Button(action: { viewModel.applyHint(type: .japaneseTranslation) }) {
                            Label("日本語訳", systemImage: "text.bubble.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(DesignSystem.Colors.textSecondary.opacity(0.2))) // 色を調整
                                .foregroundColor(DesignSystem.Colors.textSecondary) // 色を調整
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: { Task { await viewModel.passQuestion() } }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("パス")
                            }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(DesignSystem.Colors.textSecondary.opacity(0.2))) // 色を調整
                                .foregroundColor(DesignSystem.Colors.textSecondary) // 色を調整
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom) // 下に余白を追加
                }
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .overlay(FeedbackOverlay(showFeedback: $showFeedback, feedbackText: $feedbackText, feedbackColor: $feedbackColor))
        .overlay(HintOverlayView(viewModel: viewModel))
        .overlay(ResultAndExplanationOverlay(viewModel: viewModel))
    }

    private func handleAnswerSubmit(assembledChunks: [Chunk]) {
        let isCorrect = viewModel.isAnswerCorrect(userAnswer: assembledChunks)
        Task { @MainActor in
            await viewModel.submitAnswer(isCorrect: isCorrect, userAnswer: assembledChunks)
        }
    }
}



// 上部のステータスバー
struct StatusBarView: View {
    @ObservedObject var viewModel: SyntaxSprintViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("\(viewModel.comboCount) COMBO", systemImage: "flame.fill")
                    .font(.title2.bold().monospacedDigit())
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.comboCount)
                
                Spacer()
                
                Text("SCORE: \(viewModel.score)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            HStack(spacing: 4) {
                Image(systemName: "hourglass") // 時計アイコン
                    .font(.caption)
                    .foregroundColor(.secondary)
                TimeBarView(
                    remainingTime: viewModel.remainingTime,
                    initialTime: SyntaxSprintViewModel.initialTime
                )
            }
        }
    }
}

// 正解・不正解時のフィードバック演出
struct FeedbackOverlay: View {
    @Binding var showFeedback: Bool
    @Binding var feedbackText: String
    @Binding var feedbackColor: Color

    var body: some View {
        if showFeedback {
            Text(feedbackText)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(feedbackColor)
                .shadow(radius: 3)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity.animation(.easeIn(duration: 0.5))
                ))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation {
                            showFeedback = false
                        }
                    }
                }
        }
    }
}

// ヒント表示用のオーバーレイ
struct HintOverlayView: View {
    @ObservedObject var viewModel: SyntaxSprintViewModel

    var body: some View {
        if viewModel.showHint {
            Text(viewModel.hintText)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .background(DesignSystem.Colors.brandPrimary.opacity(0.8))
                .cornerRadius(10)
                .shadow(radius: 5)
                .transition(.opacity)
                .animation(.easeIn(duration: 0.3), value: viewModel.showHint)
        }
    }
}

// 時間のプログレスバー
struct TimeBarView: View {
    let remainingTime: Double
    let initialTime: Double
    
    private var progress: CGFloat {
        max(0, CGFloat(remainingTime) / CGFloat(initialTime))
    }
    
    private var barColor: Color {
        if progress < 0.2 { return .red }
        if progress < 0.5 { return .orange }
        return .green
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.3))
                Capsule()
                    .fill(barColor.gradient)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 12)
    }
}

// リザルト画面
struct SyntaxSprintResultView: View {
    @ObservedObject var viewModel: SyntaxSprintViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var showCountdown: Bool
    
    @ViewBuilder
    private func evaluationTitleView() -> some View {
        let score = viewModel.score
        if score >= 25 {
            Text("MASTER")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.pink)
        } else if score >= 15 {
            Text("EXCELLENT")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.red)
        } else if score >= 8 {
            Text("GREAT")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.orange)
        } else {
            Text("GOOD")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.green)
        }
    }

    @ViewBuilder
    private func evaluationMessageView() -> some View {
        let score = viewModel.score
        let message: String

        if score >= 25 {
            Text("""
            あなたの瞬発力はTOEIC 900点レベル！
            文の構造を完璧に理解しています。
            """)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        } else if score >= 15 {
            Text("""
            素晴らしい反射神経！TOEIC 800点台も目前です。
            """)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        } else if score >= 8 {
            Text("""
            かなり速く解けています！繰り返し挑戦して精度を上げましょう。
            """)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        } else {
            Text("""
            ナイスチャレンジ！まずは10問連続正解を目指そう。
            """)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func newHighScoreView() -> some View {
        if viewModel.isNewHighScore {
            return AnyView(Label("NEW RECORD!", systemImage: "crown.fill")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(.yellow.gradient))
                .transition(.scale.animation(.spring(response: 0.4, dampingFraction: 0.5))))
        } else {
            return AnyView(EmptyView())
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            evaluationTitleView()

            VStack {
                Text("SCORE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.score)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
            }
            
            newHighScoreView()

            HStack(spacing: 30) {
                VStack {
                    Text("MAX COMBO")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.maxCombo)")
                        .font(.title.bold())
                }
                VStack {
                    Text("HIGH SCORE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.highScore)")
                        .font(.title.bold())
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(16)
            
            evaluationMessageView()
            
            Spacer()

            VStack(spacing: 12) {
                Button { 
                    Task { @MainActor in
                        await viewModel.prepareGame()
                        showCountdown = true
                    }
                } label: {
                    Label("もう一度挑戦する", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("トレーニングに戻る") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(30)
    }
}

// 正解と解説表示用のオーバーレイ
struct ResultAndExplanationOverlay: View {
    @ObservedObject var viewModel: SyntaxSprintViewModel

    var body: some View {
        if viewModel.showResultAndExplanation {
            ZStack {
                Color.white.opacity(0.7).ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("正解")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text(viewModel.lastQuestionCorrectOrder)
                        .font(.title.bold())
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)

                    Text("解説")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    ScrollView {
                        Text(viewModel.lastQuestionExplanation)
                            .font(.body)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: 200)

                    Button("次へ") {
                        viewModel.dismissResultAndExplanation()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(20)
            }
        }
    }
}
