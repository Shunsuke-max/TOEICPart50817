import SwiftUI

/// 短時間表示される、お祝い用のパーティクルエフェクト
struct ParticleEffectView: View {
    
    // アニメーションをトリガーするためのState
    @State private var isAnimating = false
    
    // 表示するパーティクルの数
    let particleCount = 30
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { _ in
                ParticleView()
                    // ZStack内の各パーティクルを、アニメーションさせる
                    .scaleEffect(isAnimating ? .random(in: 0.8...2.0) : 0.01)
                    .offset(x: .random(in: -200...200), y: .random(in: -300...300))
                    .rotationEffect(.degrees(.random(in: -180...180)))
                    .opacity(isAnimating ? 0 : 1)
                    // 少しずつ時間差をつけてアニメーションさせる
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.6).delay(.random(in: 0...0.2)),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            // Viewが表示された瞬間にアニメーションを開始
            isAnimating = true
        }
    }
}

/// 1粒のパーティクルを表すView
private struct ParticleView: View {
    // ランダムな色と形を生成
    @State private var color = [Color.yellow, .orange, .pink, .white].randomElement()!
    @State private var shape: AnyView
    
    init() {
        // 50%の確率で星形、50%の確率で円形にする
        if Bool.random() {
            _shape = State(initialValue: AnyView(Image(systemName: "star.fill")))
        } else {
            _shape = State(initialValue: AnyView(Circle()))
        }
    }
    
    var body: some View {
        shape
            .foregroundColor(color)
            .frame(width: .random(in: 10...20), height: .random(in: 10...20))
            .shadow(color: color, radius: 5)
    }
}
