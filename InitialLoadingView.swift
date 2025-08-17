import SwiftUI

struct InitialLoadingView: View {
    
    // 表示するティップスのリスト
    private let tips = [
        "TOEIC Part5は文法と語彙の知識が鍵です。",
        "学習の習慣化がスコアアップへの一番の近道です。",
        "苦手な問題はブックマークして、何度も復習しましょう。",
        "満点を取る必要はありません。まずは目標スコアを目指しましょう！",
        "アプリの全機能を使いこなして、効率的に学習を進めよう。",
        "あなたの挑戦を、心から応援しています！"
    ]
    
    @State private var currentTip: String = ""
    @State private var tipTimer: Timer?

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // アプリのテーマに合わせたアイコン
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(DesignSystem.Colors.brandPrimary)
                .symbolEffect(.pulse) // iOS 17以降で利用可能

            // 動的に切り替わるティップス
            Text(currentTip)
                .font(DesignSystem.Fonts.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(height: 60)
                .padding(.horizontal)

            ProgressView("データを読み込んでいます...")
            
            Spacer()
        }
        .onAppear(perform: setupTimer)
        .onDisappear {
            tipTimer?.invalidate()
        }
    }
    
    private func setupTimer() {
        // 最初に一つ表示
        currentTip = tips.randomElement() ?? "ようこそ！"
        
        // 5秒ごとにティップスを更新
        tipTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentTip = tips.randomElement() ?? "ようこそ！"
            }
        }
    }
}

struct InitialLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        InitialLoadingView()
    }
}
