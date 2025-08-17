import SwiftUI

/// 今日の学習目標を達成した時に表示されるお祝いView
struct GoalAchievedView: View {
    let goalTimeMinutes: Int
    var onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            ConfettiView().zIndex(1)
            
            Color.black.opacity(0.6).ignoresSafeArea().zIndex(2)

            VStack(spacing: 20) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(Color.yellow)
                    .shadow(color: .orange, radius: 10)

                Text("目標達成！")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("今日の目標「\(goalTimeMinutes)分」の学習\nお疲れ様でした！")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Spacer().frame(height: 40)

                Button(action: onDismiss) {
                    Text("OK")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.yellow.gradient)
                        .cornerRadius(25)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
                HapticManager.shared.playSuccess()
            }
            .zIndex(3)
        }
    }
}
