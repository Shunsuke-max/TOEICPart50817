import SwiftUI

/// XP獲得アニメーションを表示する専用View
struct XPGainView: View {
    let amount: Int
    
    @State private var scale: CGFloat = 0.5
    @State private var verticalOffset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Text("+ \(amount) XP")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(DesignSystem.Colors.CourseAccent.yellow)
            .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            .scaleEffect(scale)
            .offset(y: verticalOffset)
            .opacity(opacity)
            .onAppear {
                // 表示された瞬間にアニメーションを開始
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                }
                
                // 0.5秒後に上昇とフェードアウトのアニメーションを開始
                withAnimation(.easeIn(duration: 1.0).delay(0.5)) {
                    verticalOffset = -100
                    opacity = 0
                }
            }
    }
}
