import SwiftUI
import SwiftData

struct AchievementsView: View {
    // 獲得済みの実績をデータベースから取得
    @Query(sort: \UnlockedAchievement.dateUnlocked, order: .reverse)
    private var unlockedAchievements: [UnlockedAchievement]
    
    private let columns = [GridItem(.adaptive(minimum: 150))]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                // アプリ内の全実績タイプをループ
                ForEach(AchievementType.allCases) { type in
                    badgeView(for: type)
                }
            }
            .padding()
        }
        .background(DesignSystem.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("実績・バッジ")
    }
    
    @ViewBuilder
    private func badgeView(for type: AchievementType) -> some View {
        // この実績が解除済みかどうかを判定
        let isUnlocked = unlockedAchievements.contains { $0.id == type.id }
        
        let icon = isUnlocked ? type.unlockedIcon : type.lockedIcon
        
        VStack(spacing: 10) {
            Image(systemName: icon.name)
                .font(.system(size: 50))
                .foregroundColor(icon.color)
                .frame(height: 60)
            
            Text(type.title)
                .font(.headline)
                .foregroundColor(isUnlocked ? .primary : .secondary)
            
            Text(type.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .padding()
        .frame(minHeight: 180, alignment: .top)
        .background(.regularMaterial)
        .cornerRadius(DesignSystem.Elements.cornerRadius)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AchievementsView()
        }
    }
}
