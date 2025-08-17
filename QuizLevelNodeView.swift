import SwiftUI



/// 文法コースのマップに表示する「ステージノード」のView
struct QuizLevelNodeView: View {
    let level: QuizLevel
    let status: QuizLevelStatus
    
    @State private var isAnimating: Bool = false // アニメーション用の状態変数

    // 状態に応じた色やアイコンを返す
    private var nodeColor: Color {
        switch status {
        case .locked:
            return .gray.opacity(0.6)
        case .unlocked:
            return .orange // 「挑戦中」の色
        case .cleared:
            return .green
        }
    }
    
    private var iconName: String? {
        switch status {
        case .locked:
            return "lock.fill"
        case .cleared:
            return "checkmark.circle.fill" // より目立つアイコンに変更
        default:
            return nil
        }
    }
    
    var body: some View {
        ZStack {
            // ノードの円
            Circle()
                .fill(nodeColor.gradient)
                .frame(width: 100, height: 100)
                .shadow(color: nodeColor.opacity(0.5), radius: 8, y: 4)
            
            // 「挑戦中」のステージをハイライトするアニメーション
            if status == .unlocked {
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: isAnimating ? 4 : 2)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                    .onAppear {
                        self.isAnimating = true
                    }
            }

            // ノードの枠線
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 4)
                .frame(width: 100, height: 100)
            
            // ステージ情報
            VStack {
                Text(level.stageName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
                
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.top, 2)
                }
            }
            .padding(8)
        }
        .scaleEffect(isPressed ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    @State private var isPressed = false
}

struct QuizLevelNodeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 30) {
                QuizLevelNodeView(level: QuizLevel(id: UUID().uuidString, stageId: "1", stageName: "主語と動詞", quizSetId: "S-V-1"), status: .unlocked)
                QuizLevelNodeView(level: QuizLevel(id: UUID().uuidString, stageId: "2", stageName: "時制の一致", quizSetId: "Tense-1"), status: .cleared)
                                QuizLevelNodeView(level: QuizLevel(id: UUID().uuidString, stageId: "3", stageName: "関係代名詞", quizSetId: "Relative-1"), status: .locked)
            }
        }
    }
}
