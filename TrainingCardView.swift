import SwiftUI

/// トレーニングメニューに表示されるカードのUI部品
struct TrainingCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isLocked: Bool = false
    var isDailyCleared: Bool = false // ★★★ 追加 ★★★
    var bestRecord: String? = nil // ★★★ 追加 ★★★
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .center) { // ★★★ ZStackでアイコンとロックを重ねる ★★★
                Image(systemName: icon)
                    .font(.title.weight(.bold))
                    .foregroundColor(isLocked ? .gray : .white) // ロック時はグレー
                    .frame(width: 52, height: 52)
                    .background(isLocked ? AnyGradient(Gradient(colors: [Color.gray.opacity(0.3)])) : color.gradient) // ロック時はグレーアウト
                    .cornerRadius(12)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 16)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold) // Changed to bold
                .foregroundColor(isLocked ? .gray : .primary) // ロック時はグレー
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(isLocked ? .gray.opacity(0.7) : .secondary) // ロック時はグレー
                .padding(.top, 4)
                .lineLimit(2) // 2行に制限
                .fixedSize(horizontal: false, vertical: true)
            
            if let best = bestRecord { // ★★★ 自己ベストの表示 ★★★
                Text(best)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isLocked ? DesignSystem.Colors.surfacePrimary.opacity(0.5) : DesignSystem.Colors.surfacePrimary) // ロック時は半透明
        .cornerRadius(DesignSystem.Elements.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .overlay(alignment: .topTrailing) { // ★★★ デイリークリアの証 ★★★
            if isDailyCleared {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .padding(8)
            }
        }
    }
}

struct TrainingCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // ★ タップされている時に、カードを少し縮小させる
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            // ★ アニメーションを定義（バネのような動き）
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) {
                // ★ タップ時に軽い触覚フィードバックを返す
                if configuration.isPressed {
                    HapticManager.softTap()
                }
            }
    }
}
