import SwiftUI

struct SurvivalPreparationView: View {
    let type: SurvivalViewModel.SurvivalType
    @State private var highScore: Int = 0
    
    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: [
                DesignSystem.Colors.CourseAccent.red,
                DesignSystem.Colors.CourseAccent.orange
            ])
            VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: iconName)
                .font(.system(size: 80))
                .foregroundColor(accentColor)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                
                Text(description)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true) // これを追加
            }

            HStack {
                Text("自己ベスト")
                    .font(.subheadline)
                Text("\(highScore) 問")
                    .font(.title2.bold())
                    .foregroundColor(accentColor)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
            
            Spacer()
            
            NavigationLink(destination: SurvivalModeView(type: type)) {
                    Text("挑戦する")
                        .font(DesignSystem.Fonts.headline.bold())
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(accentColor.gradient)
                        .cornerRadius(DesignSystem.Elements.cornerRadius)
                }
            }
        } // ZStackの閉じ括弧を追加
        .padding(30)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            self.highScore = UserStatsManager.shared.getSurvivalHighScore(for: type)
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    private var title: String {
        switch type {
        case .normal:
            return "Part5サバイバル"
        case .onimon:
            return "鬼問サバイバル"
        }
    }
    
    private var description: String {
        switch type {
        case .normal:
            return "ライフは1つだけ。1問でも間違えたら即ゲームオーバー。\n連続正解の限界に挑戦しよう！"
        case .onimon:
            return "超難問を突破し、真のTOEICマスターを目指せ！\n間違えたら即ゲームオーバーの鬼畜モード。"
        }
    }
    
    private var iconName: String {
        switch type {
        case .normal:
            return "shield.slash.fill"
        case .onimon:
            return "devil.fill"
        }
    }
    
    private var accentColor: Color {
        switch type {
        case .normal:
            return DesignSystem.Colors.CourseAccent.red
        case .onimon:
            return DesignSystem.Colors.CourseAccent.purple
        }
    }
    
    private var navigationTitle: String {
        switch type {
        case .normal:
            return "サバイバルモード"
        case .onimon:
            return "鬼問サバイバル"
        }
    }
}
