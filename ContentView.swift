import SwiftUI

/// アプリの全体的な表示状態を管理するためのenum
enum AppState: Equatable {
    // Equatableに準拠させるため、Equatableな型のみを関連値として持つ
    struct FailedState: Error, Equatable {
        let error: Error
        static func == (lhs: AppState.FailedState, rhs: AppState.FailedState) -> Bool {
            return lhs.error.localizedDescription == rhs.error.localizedDescription
        }
    }
    
    case loading
    case needsOnboarding
    case mainApp([Course])
    case failed(FailedState)
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.needsOnboarding, .needsOnboarding): return true
        case (.mainApp(let l), .mainApp(let r)): return l.map(\.id) == r.map(\.id)
        case (.failed(let l), .failed(let r)): return l == r
        default: return false
        }
    }
}

struct ContentView: View {
    @State private var appState: AppState = .loading
    @StateObject private var notificationManager = AppNotificationManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home

    var body: some View {
        Group {
            switch appState {
            case .loading:
                InitialLoadingView()
            
            case .needsOnboarding:
                SimplifiedOnboardingView {
                    SettingsManager.shared.hasCompletedOnboarding = true
                    Task { await loadData() }
                }
                
            case .mainApp(let courses):
                MainTabView(courses: courses, selectedTab: $selectedTab)
                
            case .failed(let errorState):
                ErrorView(error: errorState.error, onRetry: {
                    Task { await loadData() }
                })
            }
        }
        .task {
            determineInitialState()
            // アプリ起動時の実績チェックはここで行う
            notificationManager.checkForNewAchievements(context: modelContext)
        }
        // ★★★ 実績解除通知の画面をここに追加 ★★★
        .fullScreenCover(item: $notificationManager.achievementToDisplay) { achievement in
            AchievementUnlockedView(achievement: achievement) {
                // 閉じるボタンが押されたら、表示中の実績をクリアする
                notificationManager.achievementToDisplay = nil
            }
        }
    }
    
    /// アプリ起動時の初期状態を決定する
    private func determineInitialState() {
        if !SettingsManager.shared.hasCompletedOnboarding {
            appState = .needsOnboarding
        } else {
            // すべての初回フローが完了していれば、メインのデータを読み込む
            Task { await loadData() }
        }
    }
    
    /// コースデータの読み込みを行う
    private func loadData() async {
        // すでに読み込み済みの場合は何もしない
        if case .mainApp = appState { return }

        // appStateを.loadingに設定する前に、現在の状態を保持
        let currentState = appState
        if currentState != .loading {
             appState = .loading
        }
        
        do {
            let courses = try await DataService.shared.loadCourseManifest()
            appState = .mainApp(courses)
        } catch {
            print("🔥🔥🔥 データ読み込みエラー: \(error)")
            print("🔥🔥🔥 エラー詳細(Localized): \(error.localizedDescription)")
            appState = .failed(.init(error: error))
        }
    }
}

// MARK: - Sub-Views for Clarity

/// メインのタブ画面
private struct MainTabView: View {
    let courses: [Course]
    @Binding var selectedTab: Tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView(selectedTab: $selectedTab)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }
            .tag(Tab.home)

            NavigationView {
                CourseListView(courses: courses)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("コース", systemImage: "books.vertical.fill")
            }
            .tag(Tab.courses)

            NavigationView {
                TrainingMenuView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("トレーニング", systemImage: "dumbbell.fill")
                }
                .tag(Tab.training)
            
            AnalysisView()
                .tabItem {
                    Label("成績分析", systemImage: "chart.bar.fill")
                }
                .tag(Tab.analysis)
        }
    }
}

/// エラー表示と再試行ボタンのための画面
private struct ErrorView: View {
    let error: Error
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.red)
            Text("データの読み込みに失敗しました。")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("再試行", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
    }
}
