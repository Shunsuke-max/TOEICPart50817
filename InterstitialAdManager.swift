import Foundation
import GoogleMobileAds
import UIKit

class InterstitialAdManager: NSObject, FullScreenContentDelegate {
    
    // アプリ内で常に同じインスタンスを利用するためのシングルトン
    static let shared = InterstitialAdManager()
    
    private var interstitialAd: InterstitialAd?
    // 広告を閉じた後に実行する処理を保持するための変数
    private var adDismissalHandler: (() -> Void)?

    private override init() {}

    /// インタースティシャル広告を事前に読み込む
    func loadAd(withAdUnitId id: String) {
        let request = Request()
        InterstitialAd.load(with: id, request: request) { [weak self] ad, error in
            if let error = error {
                print("❌ Interstitial ad failed to load with error: \(error.localizedDescription)")
                return
            }
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
            print("✅ Interstitial ad loaded successfully.")
        }
    }

    /// 読み込んだ広告を表示する
    /// - Parameters:
    ///   - viewController: 広告を表示する元のViewController
    ///   - onDismiss: 広告が閉じられた後に実行したい処理
    func showAd(from viewController: UIViewController, onDismiss: @escaping () -> Void) {
        // Proユーザーの場合は広告を表示しない
        if SettingsManager.shared.isPremiumUser {
            onDismiss()
            return
        }

        guard let ad = self.interstitialAd else {
            print("⚠️ Interstitial ad not ready.")
            // 広告が準備できていない場合は、すぐに完了処理を呼ぶ
            onDismiss()
            return
        }
        
        self.adDismissalHandler = onDismiss
        ad.present(from: viewController)
    }
    
    // MARK: - GADFullScreenContentDelegate Methods

    // 広告の表示に失敗した
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad did fail to present full screen content with error: \(error.localizedDescription)")
        // エラーが発生した場合も、完了処理を呼んでアプリの動作を継続させる
        adDismissalHandler?()
        adDismissalHandler = nil // 念のためクリア
        // 新しい広告を読み込み直す
        self.interstitialAd = nil
    }

    // 広告が表示された
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("ℹ️ Ad will present full screen content.")
    }

    // 広告が閉じられた
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("ℹ️ Ad did dismiss full screen content.")
        // 保持しておいた完了処理を実行
        adDismissalHandler?()
        adDismissalHandler = nil // 完了したのでクリア
        // 新しい広告を読み込み直す
        self.interstitialAd = nil
    }
}
