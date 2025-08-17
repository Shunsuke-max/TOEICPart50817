import SwiftUI

// オンボーディングの各ページで表示する情報をまとめた構造体
struct OnboardingPageInfo: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
}
