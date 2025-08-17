import SwiftUI

struct NewDiagnosticPromptView: View {
    
    let targetScore: String
    var onStart: () -> Void
    
    // targetScoreに基づいて動的にメッセージを生成
    private var title: String {
        switch targetScore {
        case "TOEIC初心者 / 現在〜595点":
            return "まずは5問で、基礎力をチェックしましょう！"
        case "中級レベル / 現在600〜795点":
            return "中級の壁を越えるための、実力診断へようこそ！"
        case "上級レベル / 現在800点〜":
            return "ハイスコアの壁を超えるための実力診断へようこそ！"
        default:
            return "実力診断へようこそ！"
        }
    }
    
    private let description = "あなたのスコアUPに役立つ実力診断テストをご用意しました。たった3分で、あなたの隠れた弱点と、それを克服するための学習プランがわかります。"
    
    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: [DesignSystem.Colors.brandPrimary.opacity(0.3), .blue.opacity(0.3)])
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "target")
                    .font(.system(size: 80))
                    .foregroundColor(DesignSystem.Colors.brandPrimary)
                
                Text(title)
                    .font(DesignSystem.Fonts.largeTitle)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(DesignSystem.Fonts.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("実力診断を始める") {
                    onStart()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(DesignSystem.Spacing.large)
            .background(.ultraThinMaterial)
            .cornerRadius(DesignSystem.Elements.cornerRadius)
            .padding()
        }
    }
}
