import SwiftUI

struct AuroraBackgroundView: View {
    // 背景に使用する色の配列を受け取る
    let colors: [Color]

    var body: some View {
        ZStack {
            // 基本の背景色
            Color.clear.ignoresSafeArea()

            // 1色目の円
            if colors.indices.contains(0) {
                Circle()
                    .fill(colors[0].opacity(0.3))
                    .blur(radius: 100)
                    .offset(x: -150, y: -250)
            }

            // 2色目の円
            if colors.indices.contains(1) {
                Circle()
                    .fill(colors[1].opacity(0.3))
                    .blur(radius: 120)
                    .offset(x: 150, y: 100)
            }
        }
    }
}
