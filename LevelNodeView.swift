import SwiftUI

/// 並び替え問題のステージマップに表示する「レベルノード」のView
struct LevelNodeView: View {
    let level: Int
    let isLocked: Bool
    let isComplete: Bool
    let isCurrent: Bool // 現在挑戦中のステージか
    
    @State private var showUnlockAnimation = false
    @State private var isPulsing = false
    @State private var varisPulsing = false // 脈動アニメーションの状態
    @State private var showCompletionAnimation = false // クリア時のアニメーション
    @State private var isPressed = false // タップ時のアニメーション用

    // 状態に応じた色やアイコンを返す
    private var nodeColor: Color {
        if isCurrent { return .orange } // 挑戦中の色を最優先
        if isLocked { return .gray.opacity(0.5) }
        if isComplete { return .green }
        return color(forDifficulty: level)
    }
    
    private var iconName: String? {
        if isLocked { return "lock.fill" }
        if isComplete { return "checkmark.circle.fill" }
        return nil
    }
    
    // レベルを星で表現
    private var stars: String {
        String(repeating: "★", count: level)
    }

    var body: some View {
        ZStack {
            // ノードの円
            Circle()
                .fill(nodeColor.gradient)
                .frame(width: 80, height: 80)
                .shadow(color: nodeColor.opacity(0.5), radius: 8, y: 4)
                .scaleEffect(varisPulsing ? 1.05 : 1.0) // 脈動アニメーション

            // ノードの枠線
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 4)
                .frame(width: 80, height: 80)

            // 星のテキスト
            Text(stars)
                .font(.title2.bold())
                .foregroundColor(.white)
                .shadow(radius: 2)

            // 上部に表示するアイコン（ロック or チェックマーク）
            if let iconName = iconName {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .offset(y: -55)
                    .transition(.opacity.combined(with: .scale))
            }
            
            // クリア時のアニメーション用エフェクト
            if showCompletionAnimation {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .scaleEffect(isPressed ? 1.1 : (showUnlockAnimation ? 1.1 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showUnlockAnimation)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onChange(of: isLocked) { newValue in
            if !newValue {
                showUnlockAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showUnlockAnimation = false
                }
            }
        }
        .onChange(of: isComplete) { newValue in
            if newValue {
                showCompletionAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showCompletionAnimation = false
                }
            }
        }
        .onAppear {
            if isCurrent {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    varisPulsing = true
                }
            }
        }
        .onChange(of: isCurrent) { newValue in
            if newValue {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false // isCurrentがfalseになったらアニメーションを停止
            }
        }
        .animation(.spring(), value: isComplete)
    }
    
    /// 難易度に応じて色を返すヘルパー関数
    private func color(forDifficulty level: Int) -> Color {
        switch level {
        case 1: return DesignSystem.Colors.CourseAccent.green
        case 2: return DesignSystem.Colors.CourseAccent.orange
        case 3: return DesignSystem.Colors.CourseAccent.red
        default: return .gray
        }
    }
}
