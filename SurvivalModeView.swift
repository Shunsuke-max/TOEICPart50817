import SwiftUI

struct SurvivalModeView: View {
    @StateObject private var viewModel: SurvivalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCorrectParticles = false
    @State private var showExplanationSheet = false
    @State private var isShowingExitAlert = false
    @State private var showCountdown: Bool = true
    
    init(type: SurvivalViewModel.SurvivalType) {
        _viewModel = StateObject(wrappedValue: SurvivalViewModel(type: type))
    }
    
    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: [
                DesignSystem.Colors.CourseAccent.red,
                DesignSystem.Colors.CourseAccent.orange
            ])
            
            if showCountdown {
                CountdownView(onFinished: {
                    showCountdown = false
                    Task { await viewModel.prepareAndStartGame() }
                })
            } else {
                switch viewModel.phase {
                case .playing:
                    if viewModel.isLoading {
                        ProgressView("問題を準備中...")
                    } else {
                        gameplayView
                    }
                case .waitingForRevive:
                    revivePromptView
                    
                case .readyToResume:
                    readyToResumeView
                    
                case .gameOver:
                    resultView
                }
            }
            
            // ゲームオーバーエフェクトのオーバーレイ
            if viewModel.showGameOverEffect {
                Color.red.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showGameOverEffect)
                    .allowsHitTesting(false) // UI操作を妨げないようにする
            }
        }
        .navigationTitle(viewModel.phase == .gameOver ? "結果" : "サバイバルモード")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // 「プレイ中」の時だけ「×」ボタンを表示
                if viewModel.phase == .playing {
                    Button(action: {
                        isShowingExitAlert = true
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .alert("中断しますか？", isPresented: $isShowingExitAlert) {
            Button("中断する", role: .destructive) {
                dismiss()
            }
            Button("続ける", role: .cancel) {}
        } message: {
            Text("現在のスコアは保存されません。")
        }
        .alert("エラー", isPresented: $viewModel.showingErrorAlert) { // 追加
            Button("OK") { dismiss() }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーが発生しました。")
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    // MARK: - Subviews
    
    private var gameplayView: some View {
            VStack {
                // タイマープログレスバー
                ProgressView(value: viewModel.timeRemaining, total: viewModel.timeLimit)
                    .progressViewStyle(.linear)
                    .tint(viewModel.timeRemaining <= 5 ? .red : .yellow) // 残り時間で色を変える
                    .scaleEffect(viewModel.timeRemaining <= 5 && Int(viewModel.timeRemaining * 10) % 10 < 5 ? 1.05 : 1.0) // 点滅効果
                    .animation(.easeInOut(duration: 0.1), value: viewModel.timeRemaining) // 点滅アニメーション
                    .padding(.horizontal)

                HStack {
                    Label("連続正解: \(viewModel.score)", systemImage: "checkmark.circle.fill")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundColor(.green)
                        .symbolEffect(.bounce.up, value: viewModel.score) // 正解時のバウンスアニメーション
                    Spacer()
                    Text("ライフ: 1")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundColor(.red) // ライフが1つであることを強調
                }
                .padding()

                if let engineVM = viewModel.currentEngineViewModel {
                    QuizEngineView(
                        viewModel: engineVM,
                        onSelectOption: { index in
                            viewModel.selectOption(at: index)
                        },
                        onNextQuestion: {
                            withAnimation {
                                viewModel.moveToNextQuestion()
                            }
                        },
                        onBookmark: nil,
                        isBookmarked: nil
                    )
                } else {
                    ProgressView()
                    Spacer()
                }
            }
        }
    
    private var revivePromptView: some View {
         VStack(spacing: 25) {
             Spacer()
             
             Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                 .font(.system(size: 80))
                 .foregroundColor(.orange)
             
             VStack(spacing: 10) {
                 Text("残念、不正解です！")
                     .font(.largeTitle.bold())
                 Text("動画広告を視聴して、一度だけ復活しますか？")
                     .font(.headline)
                     .foregroundColor(.secondary)
                     .multilineTextAlignment(.center)
             }
             
             Text("現在のスコア: \(viewModel.score) 問")
                 .font(.title2.bold())
             
             Spacer()
             
             VStack(spacing: 12) {
                 Button(action: {
                     if let vc = getRootViewController() {
                         RewardedAdManager.shared.showAd(from: vc, onDismiss: { rewarded in
                             DispatchQueue.main.async {
                                 if rewarded {
                                     viewModel.grantRevive()
                                 } else {
                                     viewModel.forceEndGame()
                                 }
                             }
                         })
                     }
                 }) {
                                 Label("動画を見て復活する", systemImage: "play.tv.fill")
                             }
                             .buttonStyle(PrimaryButtonStyle())
                             .tint(.orange)
                             
                             Button("ゲームオーバーにする") {
                                 viewModel.forceEndGame()
                             }
                             .buttonStyle(SecondaryButtonStyle())
                         }
                     }
                     .padding(30)
                     .onAppear {
                         RewardedAdManager.shared.loadAd()
                     }
                 }
    
    private var readyToResumeView: some View {
            VStack(spacing: 25) {
                Spacer()
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 10) {
                    Text("挑戦権を獲得しました！")
                        .font(.largeTitle.bold())
                    Text("準備ができたら、下のボタンから挑戦を再開してください。")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        // ★ ユーザーのタイミングで挑戦を再開
                        viewModel.resumeChallenge()
                    }) {
                        Label("挑戦を始める", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .tint(.green)
                    
                    Button("トレーニングに戻る") {
                        // ゲームを終了してホームに戻る
                        dismiss()
                    }
                }
            }
            .padding(30)
        }
    
    private var resultView: some View {
        SurvivalResultView(
            score: viewModel.score,
            highScore: viewModel.highScore,
            correctQuestions: viewModel.correctQuestions,
            incorrectQuestions: viewModel.incorrectQuestions,
            onRestart: {
                Task { await viewModel.prepareAndStartGame() }
            },
            onBackToMenu: {
                dismiss()
            }
        )
    }
    @ViewBuilder
    private func explanationSheet(for question: Question) -> some View {
        VStack(spacing: 0) {
            // --- ヘッダー ---
            HStack {
                Text("問題の復習")
                    .font(.headline)
                Spacer()
                Button("閉じる") {
                    showExplanationSheet = false
                }
            }
            .padding()
            .background(.thinMaterial)

            Divider()
            
            // --- コンテンツ本体 ---
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Q. \(question.questionText)")
                        .font(.title2.bold())
                    
                    Divider()
                    
                    ForEach(question.options.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: index == question.correctAnswerIndex ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(index == question.correctAnswerIndex ? .green : .secondary)
                            Text(question.options[index])
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Divider()
                    
                    Text("解説")
                        .font(.headline)
                    Text(question.explanation)
                        .font(.body)
                }
                .padding()
                // ★★★ この modifier が重要 ★★★
                // 「横幅は、利用可能なスペースを全て使ってください」と明示的に指示
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
