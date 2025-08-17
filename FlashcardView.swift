import SwiftUI

/// タップで裏返るアニメーションを持つフラッシュカードUI
struct FlashcardView<Front: View, Back: View>: View {
    let front: Front
    let back: Back
    
    @State private var isFlipped = false
    @State private var rotation: Double = 0
    
    init(@ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self.front = front()
        self.back = back()
    }
    
    var body: some View {
        ZStack {
                front
                    .opacity(isFlipped ? 0 : 1)

                back
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(
                                    .degrees(180), // 常に180度回転させておく
                                    axis: (x: 0.0, y: 1.0, z: 0.0) // Y軸で回転
                                )
            }
        .frame(maxWidth: .infinity, minHeight: 250)
            .background(DesignSystem.Colors.surfacePrimary)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
            .onTapGesture {
                flipCard()
            }
        }
    
    private func flipCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            rotation += 180
        }
        isFlipped.toggle()
        HapticManager.softTap()
    }
}
