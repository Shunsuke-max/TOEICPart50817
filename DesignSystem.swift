import SwiftUI

// MARK: - Design System Definition

struct DesignSystem {
    
    /// アプリ全体で利用するカラーパレット
    enum Colors {
        // 基調色：セルリアンブルー
        static let brandPrimary = Color(hex: "#0474CD")
        static let brandSecondary = Color(hex: "#E6F4FF")
        
        // テキストカラー
        static let textPrimary = Color(hex: "#1A1A1A")
        static let textSecondary = Color(hex: "#8A8A8E") // secondary a gray color
        
        // 背景・サーフェスカラー
        static let backgroundPrimary = Color.white // systemGroupedBackground light mode
        static let surfacePrimary = Color.white
        
        // 各コースのアクセントカラー（既存の色を流用）
        static let accentRed = Color.red
        static let accentOrange = Color.orange
        static let accentBlue = Color.blue
        static let accentYellow = Color.yellow
        static let accentPurple = Color.purple
        static let accentGreen = Color.green
        
        enum CourseAccent {
                    static let red = Color(hex: "#E76F51")      // テラコッタ
                    static let orange = Color(hex: "#F4A261")   // サンドオレンジ
                    static let blue = Color(hex: "#2A9D8F")     // ティールグリーン
                    static let yellow = Color(hex: "#E9C46A")   // サフランイエロー
                    static let purple = Color(hex: "#8E7DBE")   // ラベンダー
                    static let green = Color(hex: "#6A994E")    // オリーブグリーン
                    static let indigo = Color(hex: "#5E60CE")   // インディゴ
                }
    }
    
    /// アプリ全体で利用するフォントスタイル
    enum Fonts {
        static let largeTitle = Font.largeTitle.weight(.heavy)
        static let title = Font.title3.weight(.bold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let caption = Font.caption
    }
    
    /// アプリ全体で利用するスペーシング（余白）
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
    
    /// その他のUI要素の定義
    enum Elements {
        static let cornerRadius: CGFloat = 16
    }
}

// MARK: - Reusable Components (ViewModifier)

/// カードUIを適用するためのViewModifier
struct CardViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.medium)
            .background(.regularMaterial)
            .cornerRadius(DesignSystem.Elements.cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// Viewから使いやすくするための拡張
extension View {
    func cardStyle() -> some View {
        self.modifier(CardViewModifier())
    }
}


// MARK: - Color Extension for Hex values

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
