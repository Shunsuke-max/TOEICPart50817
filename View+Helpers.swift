import SwiftUI
import UIKit

// UIViewControllerを見つけるためのヘルパー
extension View {
    func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        return windowScene.windows.first { $0.isKeyWindow }?.rootViewController
    }
}
