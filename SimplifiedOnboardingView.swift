import SwiftUI

struct SimplifiedOnboardingView: View {
    
    var onComplete: () -> Void
    
    // 選択肢の文言を改善案Aに変更
    private let scoreOptions = [
        "TOEIC初心者 / 現在〜595点",
        "中級レベル / 現在600〜795点",
        "上級レベル / 現在800点〜"
    ]
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 40) {
                    VStack(spacing: 15) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundColor(DesignSystem.Colors.brandPrimary)
                        Text("ようこそ！")
                            .font(DesignSystem.Fonts.largeTitle)
                        Text("TOEIC Part5 実践問題へようこそ！\nこのアプリで、Part5の解答スピードと正答率を劇的にアップさせましょう。")
                            .font(DesignSystem.Fonts.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    
                    VStack(spacing: 20) {
                        Text("あなたの現在のレベルを教えてください") // 文言を修正
                            .font(DesignSystem.Fonts.title)
                        Text("あなたに最適な学習プランをご提案します。")
                            .font(DesignSystem.Fonts.body)
                            .foregroundColor(.secondary)
                        
                        // 1タップ選択ボタンに変更
                        ForEach(scoreOptions, id: \.self) { option in
                            OneTapSelectionButton(option: option, onSelect: {
                                // 選択したスコアを保存
                                SettingsManager.shared.targetScore = option
                                // 0.5秒後に完了処理を呼ぶ
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    onComplete()
                                }
                            })
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary.ignoresSafeArea())
    }
}

// 1タップで選択・遷移するボタン
private struct OneTapSelectionButton: View {
    let option: String
    let onSelect: () -> Void
    
    @State private var isSelected = false
    
    var body: some View {
        Button(action: {
            guard !isSelected else { return }
            isSelected = true
            onSelect()
        }) {
            HStack {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                    Text("了解！")
                        .fontWeight(.bold)
                } else {
                    Text(option)
                }
                Spacer()
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding()
            .frame(height: 60) // 高さを固定
            .background(isSelected ? DesignSystem.Colors.brandPrimary : DesignSystem.Colors.surfacePrimary)
            .cornerRadius(DesignSystem.Elements.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Elements.cornerRadius)
                    .stroke(DesignSystem.Colors.brandPrimary, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}
