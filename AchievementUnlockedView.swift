import SwiftUI

/// 実績解除時に表示されるお祝いView
struct AchievementUnlockedView: View {
    let achievement: AchievementType
    var onDismiss: () -> Void
    
    @State private var textScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景に紙吹雪
            ConfettiView().zIndex(1)
            
            Color.black.opacity(0.6).ignoresSafeArea().zIndex(2)
            
            VStack(spacing: 20) {
                Image(systemName: achievement.unlockedIcon.name)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(achievement.unlockedIcon.color)
                    .symbolEffect(.bounce.up.byLayer) // アイコンが跳ねるエフェクト

                Text("実績解除！")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: achievement.unlockedIcon.color, radius: 5)
                
                VStack {
                    Text(achievement.title)
                        .font(.title2.bold())
                    Text(achievement.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                
                Spacer().frame(height: 40)
                
                Button(action: onDismiss) {
                    Text("やったね！")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(achievement.unlockedIcon.color.gradient)
                        .cornerRadius(25)
                }
            }
            .scaleEffect(textScale)
            .opacity(textOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    textScale = 1.0
                    textOpacity = 1.0
                }
                HapticManager.shared.playSuccess()
            }
            .zIndex(3)
        }
    }
}
