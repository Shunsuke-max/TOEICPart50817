import SwiftUI

struct ConfettiView: View {
    // アニメーションを発動させるためのスイッチ
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<100) { _ in
                Circle()
                    .fill(Color(hue: .random(in: 0...1), saturation: 1, brightness: 1))
                    .frame(width: .random(in: 5...10), height: .random(in: 5...10))
                    .offset(x: .random(in: -200...200), y: .random(in: -500...500))
                    .opacity(.random(in: 0.5...1))
                    .animation(
                        // ★★★ アニメーションのきっかけを、毎回生成されるUUID()から、
                        // 安定した`animate`変数に変更
                        Animation.spring().repeatForever(autoreverses: false).speed(.random(in: 0.1...0.5)),
                        value: animate
                    )
            }
        }
        .onAppear {
            // Viewが表示された瞬間に一度だけスイッチをONにして、アニメーションを開始させる
            self.animate = true
        }
    }
}
