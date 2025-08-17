import SwiftUI

/// 各種学習メニューを一覧表示する画面
struct TrainingMenuView: View {
    // --- State Variables ---
    @State private var canPlaySprint: Bool = false
    @State private var showSprintPaywall: Bool = false
    @State private var navigateToSprint: Bool = false
    @State private var survivalPlayability: GameModeManager.Playability = .available
    @State private var showSurvivalAdPrompt = false
    @State private var navigateToSurvival = false
    @State private var showUsageSheet = false
    @State private var selectedInformationContent: String? = nil
    
    @StateObject private var viewModel = HomeViewModel() 
    
    // --- Layout Definition ---
    // 2列のグリッドレイアウトを定義
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: [
                DesignSystem.Colors.CourseAccent.purple,
                DesignSystem.Colors.CourseAccent.blue
            ])
            
            ScrollView {
                VStack(alignment: .leading, spacing: 40) { // Spacing increased
                    
                    // --- 1. 最重要機能セクション (横長カード) ---
                    HeaderView(title: "メインチャレンジ", showInfoButton: true, infoContent: "Part5模試は、本番形式であなたの実力を試すことができます。全問解答後には詳細な解説が表示されます。", onInfoButtonTapped: { content in
                        self.selectedInformationContent = content
                        self.showUsageSheet = true
                    })
                    
                                            NavigationLink(destination: MockTestSelectionView().toolbar(.hidden, for: .tabBar)) {
                        FeaturedCardView(title: "Part 5 模試", subtitle: "本番形式で実力を試そう", icon: "doc.text.magnifyingglass.fill", color: DesignSystem.Colors.CourseAccent.indigo)
                            .overlay(alignment: .topTrailing) {
                                Text("まずはここから！")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(DesignSystem.Colors.CourseAccent.orange) // Changed color
                                    .cornerRadius(8)
                                    .offset(x: -8, y: 8)
                            }
                    }
                    .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            NavigationLink(destination: VocabularyDrillSetupView().toolbar(.hidden, for: .tabBar)) {
                                                            TrainingCardView(
                                                                title: "語彙力ドリル",
                                                                subtitle: "レベルや問題数を自由に設定",
                                                                icon: "text.book.closed.fill", // Changed to filled
                                                                color: DesignSystem.Colors.CourseAccent.indigo
                                                            )
                                                        }
                        
                        // NavigationLink(destination: ScrambleQuizListView().toolbar(.hidden, for: .tabBar)) {
                        //     TrainingCardView(title: "並び替え", subtitle: "語順の感覚を鍛えよう！", icon: "arrow.left.arrow.right", color: DesignSystem.Colors.CourseAccent.green)
                        // }

                        // ★★★ 復習クイズのカードを追加 ★★★
                        // let isReviewCardLocked = false
                        // NavigationLink(destination: ReviewQuizSetupView().toolbar(.hidden, for: .tabBar)) {
                        //     TrainingCardView(
                        //         title: "苦手な単語を復習",
                        //         subtitle: viewModel.reviewState.subtitle,
                        //         icon: "arrow.triangle.2.circlepath",
                        //         color: DesignSystem.Colors.CourseAccent.orange,
                        //         isLocked: isReviewCardLocked
                        //     )
                        // }
                        // .disabled(isReviewCardLocked) // ロックされている場合は無効化
                    }
                    .padding(.horizontal)

                    // --- 3. ゲームモードセクション (2列グリッド) ---
                    HeaderView(title: "ゲームモード", showInfoButton: true, infoContent: "各ゲームモードでは、異なる形式で実力を試すことができます。それぞれのルールに従ってハイスコアを目指しましょう。", onInfoButtonTapped: { content in
                        self.selectedInformationContent = content
                        self.showUsageSheet = true
                    })
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        sprintCard
                        
                        NavigationLink(destination: TimeAttackSetupView().toolbar(.hidden, for: .tabBar)) {
                            TrainingCardView(
                                title: "Part5タイムアタック",
                                subtitle: "5分間で限界に挑戦",
                                icon: "stopwatch.fill",
                                color: .purple,
                                isDailyCleared: GameModeManager.shared.hasPlayedTimeAttackToday(), // ★★★ 追加 ★★★
                                bestRecord: "ベスト: \(UserStatsManager.shared.getTimeAttackHighScore())点" // ★★★ 追加 ★★★
                            )
                        }
                        
                        // survivalCard // コメントアウト
                        
                        // NavigationLink(destination: SurvivalPreparationView(type: .onimon).toolbar(.hidden, for: .tabBar)) {
                        //     TrainingCardView(
                        //         title: "鬼問サバイバル",
                        //         subtitle: GameModeManager.shared.isOnimonSurvivalUnlocked() ? "超難問に挑戦！1ミスで即終了" : "Part5サバイバルで10問以上連続正解で解放！", // ★★★ サブタイトルを動的に変更 ★★★
                        //         icon: "flame.fill",
                        //         color: .black,
                        //         isLocked: !GameModeManager.shared.isOnimonSurvivalUnlocked(),
                        //         isDailyCleared: GameModeManager.shared.hasPlayedOnimonSurvivalToday(),
                        //         bestRecord: "最高記録: \(UserStatsManager.shared.getSurvivalHighScore(for: .onimon))問連続正解"
                        //     )
                        // }
                        // .disabled(!GameModeManager.shared.isOnimonSurvivalUnlocked()) // ★★★ ロック時は無効化 ★★★
                    }
                    .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
            }
            .onAppear {
                self.canPlaySprint = GameModeManager.shared.canPlaySyntaxSprint()
                self.survivalPlayability = GameModeManager.shared.checkSurvivalPlayability()
            }
            .sheet(isPresented: $showUsageSheet) {
                InformationSheetView(content: selectedInformationContent ?? "")
            }
            .buttonStyle(TrainingCardButtonStyle())
            .alert("挑戦回数を回復しますか？", isPresented: $showSurvivalAdPrompt) {
                Button("動画を見てプレイする") {
                    // ★★★ ここからが変更箇所 ★★★
                    if let vc = getRootViewController() {
                        RewardedAdManager.shared.showAd(from: vc) { rewarded in
                            if rewarded {
                                print("✅ 広告視聴成功。追加プレイ権を獲得。")
                                GameModeManager.shared.recordSurvivalAdPlay()
                                navigateToSurvival = true
                            } else {
                                print("⚠️ 広告が途中で閉じられました。")
                            }
                        }
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("広告を視聴すると、本日もう一回だけサバイバルモードに挑戦できます。")
            }
        }
    
            
            // ★★★ Syntax Sprint専用のカードを生成する部品 ★★★
            private var sprintCard: some View {
                VStack {
                    NavigationLink(destination: SyntaxSprintSetupView().toolbar(.hidden, for: .tabBar), isActive: $navigateToSprint) { EmptyView() }
                    
                    TrainingCardView(
                        title: "語順トレーニング",
                        subtitle: "バラバラの単語を組み立てて、英語の「語順感覚」をマスター！",
                        icon: "bolt.fill", // ★ アイコンを変更
                        color: DesignSystem.Colors.CourseAccent.yellow,
                        isDailyCleared: GameModeManager.shared.hasPlayedSyntaxSprintToday(), // ★★★ 追加 ★★★
                        bestRecord: "ベスト: \(UserStatsManager.shared.getSyntaxSprintRecord().highScore)点 / \(UserStatsManager.shared.getSyntaxSprintRecord().maxCombo)コンボ" // ★★★ 追加 ★★★
                    )
                    .overlay(
                        // プレイ不可で、Proユーザーでない場合に時計アイコンを表示
                        !canPlaySprint && !SettingsManager.shared.isPremiumUser ?
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.black.opacity(0.6))
                            .clipShape(Circle()) : nil
                    )
                    .onTapGesture {
                        if canPlaySprint {
                            navigateToSprint = true
                        } else if !SettingsManager.shared.isPremiumUser {
                            showSprintPaywall = true
                        }
                    }
                }
            }
            
            private var survivalCard: some View {
                VStack {
                    // プログラムによる画面遷移のための非表示NavigationLink
                    NavigationLink(destination: SurvivalPreparationView(type: .normal).toolbar(.hidden, for: .tabBar), isActive: $navigateToSurvival) { EmptyView() }
                    
                    Button(action: {
                        // カードがタップされたときの処理
                        switch survivalPlayability {
                        case .available:
                            // 通常プレイ可能なら、プレイ日時を記録して遷移
                            GameModeManager.shared.recordSurvivalPlay()
                            navigateToSurvival = true
                        case .adAvailable:
                            // 広告を見ればプレイ可能なら、アラートを表示
                            showSurvivalAdPrompt = true
                        case .onCooldown:
                            // プレイ不可の場合は何もしない（UIでフィードバック済み）
                            break
                        }
                    }) {
                        TrainingCardView(
                            title: "Part5サバイバル",
                            subtitle: survivalCardSubtitle(),
                            icon: "heart.slash.fill",
                            color: .red,
                            isDailyCleared: GameModeManager.shared.hasPlayedSurvivalToday(), // ★★★ 追加 ★★★
                            bestRecord: "最高記録: \(UserStatsManager.shared.getSurvivalHighScore(for: .normal))問連続正解" // ★★★ 追加 ★★★
                        )
                        .overlay(
                            // プレイ不可の場合のみロックアイコンを表示
                            survivalPlayability == .onCooldown ?
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(.black.opacity(0.6))
                                .clipShape(Circle()) : nil
                        )
                    }
                    // プレイ不可ならボタンを無効化
                    .disabled(survivalPlayability == .onCooldown)
                }
            }
            
            // ★★★ サバイバルカードのサブタイトルを動的に変更するヘルパー関数 ★★★
            private func survivalCardSubtitle() -> String {
                switch survivalPlayability {
                case .available:
                    return "1問でも間違えたら即終了"
                case .adAvailable:
                    return "広告視聴でもう一回挑戦"
                case .onCooldown:
                    return "本日の挑戦は終了しました"
                }
            }
            
            // ★★★ ヘッダーの見た目を統一するための部品 ★★★
            private struct HeaderView: View {
                let title: String
                var showInfoButton: Bool = false
                var infoContent: String? = nil
                var onInfoButtonTapped: ((String) -> Void)? = nil

                var body: some View {
                    HStack {
                        Text(title)
                            .font(.title2.bold())
                        if showInfoButton {
                            Button(action: {
                                if let content = infoContent {
                                    onInfoButtonTapped?(content)
                                }
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
        }

