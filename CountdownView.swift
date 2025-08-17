import SwiftUI

struct CountdownView: View {
    let countFrom: Int
    let onFinished: () -> Void
    
    @State private var countdown: Int
    @State private var showGo: Bool = false
    @State private var showInitialMessage: Bool = true // 追加: 初期メッセージ表示用
    @State private var backgroundScale: CGFloat = 0.0 // 背景エフェクト用
    @State private var backgroundOpacity: Double = 0.0 // 背景エフェクト用
    
    init(countFrom: Int = 3, onFinished: @escaping () -> Void) {
        self.countFrom = countFrom
        self.onFinished = onFinished
        _countdown = State(initialValue: countFrom)
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            
            // 背景エフェクト
            Circle()
                .fill(DesignSystem.Colors.brandPrimary.opacity(backgroundOpacity))
                .scaleEffect(backgroundScale)
                .animation(.easeOut(duration: 0.5), value: backgroundScale)
                .animation(.easeOut(duration: 0.5), value: backgroundOpacity)
            
            if showInitialMessage {
                Text("準備中...")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .transition(.opacity)
            } else if showGo {
                Text("START!")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundColor(.white) // 文字色を白に変更
                    .padding(.horizontal, 30) // 横方向のパディング
                    .padding(.vertical, 15) // 縦方向のパディング
                    .background(Capsule().fill(Color.black.opacity(0.4))) // 半透明の黒いカプセル背景
                    .scaleEffect(showGo ? 1.2 : 1.0) // START!表示時に少し拡大
                    .blur(radius: showGo ? 0 : 10) // START!表示時にぼかしを解除
                    .opacity(1.0)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showGo) // START!表示時のアニメーション
            } else {
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .heavy, design: .rounded))
                    .foregroundColor(.white) // 文字色を白に変更
                    .padding(.horizontal, 40) // 横方向のパディング
                    .padding(.vertical, 20) // 縦方向のパディング
                    .background(Circle().fill(Color.black.opacity(0.4))) // 半透明の黒い円形背景
                    .id(countdown) // countdownが変わるたびにViewを再生成してアニメーションをトリガー
                    .scaleEffect(1.0) // 初期スケール
                    .rotationEffect(.degrees(0)) // 初期回転
                    .transition(.scale(scale: 0.5).combined(with: .opacity)) // スケールとフェードイン/アウト
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdown) // 数字切り替え時のアニメーション
                    .onAppear { // 数字が表示されるたびにアニメーションをトリガー
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            backgroundScale = 1.0
                            backgroundOpacity = 0.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                backgroundScale = 0.0
                                backgroundOpacity = 0.0
                            }
                        }
                    }
            }
        }
        .onAppear(perform: startInitialPhase)
    }
    
    private func startInitialPhase() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1秒間「準備中...」を表示
            withAnimation {
                showInitialMessage = false
            }
            startCountdown()
        }
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
                HapticManager.mediumImpact() // 触覚フィードバック
                SoundManager.shared.playSound(named: "countdown_tick.wav") // 効果音 (要追加)
                if countdown == 0 {
                    showGo = true
                    timer.invalidate()
                    HapticManager.heavyImpact() // 強い触覚フィードバック
                    SoundManager.shared.playSound(named: "countdown_go.wav") // 効果音 (要追加)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // "START!"表示のための短い遅延
                        print("DEBUG: Countdown timer finished. Calling onFinished()...")
                        onFinished()
                    }
                }
            }
        }
    }
}

struct CountdownView_Previews: PreviewProvider {
    static var previews: some View {
        CountdownView(onFinished: { print("Countdown finished!") })
    }
}
