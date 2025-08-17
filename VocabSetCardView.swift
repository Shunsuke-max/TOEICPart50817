import SwiftUI

struct VocabSetCardView: View {
    let quizSet: VocabularyQuizSet
    let progress: Double // 0.0 ~ 1.0
    let isNextUp: Bool // 次にやるべき課題か
    let accentColor: Color // 新しく追加するアクセントカラー
    
    // 状態に応じた色やテキストを返す
    private var status: (color: Color, text: String, isPerfect: Bool) {
        // ★★★ progressが1.0以上（満点）の場合の分岐を追加 ★★★
        if progress >= 1.0 {
            return (.yellow, "👑 Perfect!", true)
        } else if progress >= 0.8 { // 80%以上の場合
            let score = Int(progress * Double(quizSet.questions.count))
            return (.green, "最高スコア: \(score) / \(quizSet.questions.count)", false)
        } else if progress > 0 { // 1〜79%の場合
            let score = Int(progress * Double(quizSet.questions.count))
            return (.orange, "最高スコア: \(score) / \(quizSet.questions.count)", false)
        } else { // 未挑戦の場合
            return (DesignSystem.Colors.textPrimary, "\(quizSet.questions.count) 問収録", false)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 左側のアイコンと進捗サークル
            ZStack {
                let isPerfect = status.isPerfect // progress >= 1.0
                let isCompletedEnough = progress >= 0.8 // 80%以上

                // 背景の円
                Circle()
                    .stroke(isCompletedEnough ? Color.green.opacity(0.3) : accentColor.opacity(0.3), lineWidth: 5)
                
                // 進捗を示す円弧
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(isCompletedEnough ? Color.green : accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                // アイコン
                if isPerfect {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(status.color) // 黄色
                        .shadow(color: status.color, radius: 5)
                        .scaleEffect(1.1)
                } else if isCompletedEnough {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green) // 緑色のチェックマーク
                } else {
                    Image(systemName: "\(quizSet.order).circle.fill")
                        .font(.title3)
                        .foregroundColor(accentColor) // 青、オレンジなど
                }
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(quizSet.setName)
                    .font(.headline.bold())
                    .foregroundColor(.primary)

                // ★★★ テキストの色指定を修正 ★★★
                Text(status.text)
                    .font(.subheadline)
                    .fontWeight(.medium) // 少し太くして視認性を上げる
                    .foregroundColor(status.color) // 状態に合わせた色を適用
            }
            
            Spacer()
        }
        .padding(12)
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(16)
        .overlay(
            // 次に挑戦すべきカードであれば、枠線でハイライトする
            RoundedRectangle(cornerRadius: 16)
                .stroke(isNextUp ? Color.blue : Color.clear, lineWidth: 3)
        )
        .animation(.easeInOut, value: progress)
    }
}
