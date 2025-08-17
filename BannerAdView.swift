import SwiftUI
import GoogleMobileAds
import UIKit

struct BannerAdView: UIViewRepresentable {
    
    var adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner) // GADAdSizeBannerからAdSize.bannerに変更
        bannerView.adUnitID = adUnitID
        
        // 広告を表示するためのViewControllerを探して設定
        bannerView.rootViewController = UIApplication.shared.connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow }?.rootViewController
        
        // デリゲートを設定して、広告の読み込みイベントをハンドリング
        bannerView.delegate = context.coordinator
        // 広告を読み込む
        bannerView.load(Request()) // GADRequestからRequest()に変更
        
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // SwiftUIからUIKitへの更新が必要な場合はここに書くが、今回は不要
    }
    
    // デリゲートを管理するためのCoordinator
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // 広告のライフサイクルイベントをハンドリングするためのデリゲートクラス
    class Coordinator: NSObject, BannerViewDelegate {
        // 広告が正常に受信されたときの処理
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Banner ad received successfully.")
        }

        // 広告の受信に失敗したときの処理
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load with error: \(error.localizedDescription)")
        }
    }
}
