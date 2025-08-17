import SwiftUI

/// ストリークのマイルストーン達成時に表示されるお祝いView
struct MilestoneUnlockedView: View {
    let days: Int
    let message: String
    var onDismiss: () -> Void
    
    @State private var textScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景に紙吹雪
            ConfettiView().zIndex(1)
            
            Color.black.opacity(0.6).ignoresSafeArea().zIndex(2)
            
            VStack(spacing: 20) {
                Image(systemName: "star.leadinghalf.filled")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.yellow)
                    .symbolEffect(.variableColor.iterative.reversing)

                Text("\(days)日間 連続学習達成！")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .yellow, radius: 5)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Spacer().frame(height: 40)
                
                Button(action: onDismiss) {
                    Text("OK")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.yellow)
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
