import SwiftUI

struct NotificationPermissionPromptView: View {
    var onProceed: () -> Void
    
    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: [DesignSystem.Colors.brandPrimary.opacity(0.3), .blue.opacity(0.3)])
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("学習の継続をサポートします")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text("毎日の学習リマインダーや、デイリーミッションの更新通知で、あなたの学習習慣を強力にサポートします。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("通知をオンにする") {
                    AppNotificationManager.shared.requestNotificationAuthorization()
                    onProceed()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("後で設定する") {
                    onProceed()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(DesignSystem.Elements.cornerRadius)
            .padding()
        }
    }
}

struct NotificationPermissionPromptView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPermissionPromptView(onProceed: {})
    }
}
