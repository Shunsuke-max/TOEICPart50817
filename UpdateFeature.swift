import SwiftUI

/// アプリのアップデート内容（新機能や改善点）を表すための構造体
struct UpdateFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

/// 「What's New」画面のUI
struct WhatsNewView: View {
    
    /// この画面を閉じるためのアクション
    var onDismiss: () -> Void
    
    // --- ここに今回のアップデート内容を記述します ---
    private let features: [UpdateFeature] = [
        .init(icon: "flame.circle.fill",
              iconColor: .orange,
              title: "今日の復習 (SRS機能)",
              description: "間違えた問題を最適なタイミングで復習できる機能を追加しました。効率的に弱点を克服しましょう！"),
        .init(icon: "calendar.badge.checkmark",
              iconColor: .blue,
              title: "学習カレンダーの追加",
              description: "成績分析画面で、学習した日や継続日数が一目でわかるカレンダーを追加しました。"),
        .init(icon: "paperplane.fill",
              iconColor: .green,
              title: "フィードバック機能の改善",
              description: "設定画面から、ご意見や不具合報告を簡単に送れるようになりました。"),
        .init(icon: "wrench.and.screwdriver.fill",
              iconColor: .gray,
              title: "パフォーマンスの改善と不具合修正",
              description: "いくつかの細かい不具合を修正し、アプリ全体の動作をより快適にしました。")
    ]
    // --- ここまで ---

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)
            
            Image(systemName: "sparkles")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(DesignSystem.Colors.brandPrimary)
                .padding()

            Text("最新情報")
                .font(.largeTitle.bold())
                .padding(.bottom, 5)

            Text("アプリが新しくなりました！")
                .font(.headline)
                .foregroundColor(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    ForEach(features) { feature in
                        HStack(spacing: 20) {
                            Image(systemName: feature.icon)
                                .font(.title)
                                .foregroundColor(feature.iconColor)
                                .frame(width: 45)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(feature.title)
                                    .font(.headline)
                                Text(feature.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(30)
            }
            
            // 閉じるボタン
            Button(action: onDismiss) {
                Text("続ける")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.brandPrimary)
                    .cornerRadius(DesignSystem.Elements.cornerRadius)
            }
            .padding([.horizontal, .bottom], 30)
        }
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(onDismiss: {})
    }
}
