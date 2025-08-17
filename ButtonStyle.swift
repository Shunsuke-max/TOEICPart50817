import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled // 追加

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? DesignSystem.Colors.brandPrimary.opacity(0.8) : DesignSystem.Colors.brandPrimary) // 押された時と通常時の色
            .cornerRadius(DesignSystem.Elements.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) {
                if configuration.isPressed {
                    HapticManager.rigidTap()
                }
            }
            .opacity(isEnabled ? 1.0 : 0.5) // isEnabled を使用
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled // 追加
    var color: Color = .accentColor
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(color)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.15))
            .cornerRadius(DesignSystem.Elements.cornerRadius)
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.Elements.cornerRadius).stroke(color, lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) {
                if configuration.isPressed {
                    HapticManager.rigidTap()
                }
            }
            .opacity(isEnabled ? 1.0 : 0.5) // isEnabled を使用
    }
}
