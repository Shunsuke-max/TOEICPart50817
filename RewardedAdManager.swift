import SwiftUI
import GoogleMobileAds
import UIKit

/// 動画リワード広告の読み込みと表示を管理するクラス
@MainActor
class RewardedAdManager: NSObject, FullScreenContentDelegate {
    
    static let shared = RewardedAdManager()
    
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    private var rewardedAd: RewardedAd?
    
    private var adDismissalHandler: ((_ wasRewarded: Bool) -> Void)?
    private var rewardGranted = false

    private override init() {}

    func loadAd() {
        guard rewardedAd == nil else { return }
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("❌ Rewarded ad failed to load with error: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            print("✅ Rewarded ad loaded successfully.")
        }
    }

    func showAd(from viewController: UIViewController, onDismiss: @escaping (_ wasRewarded: Bool) -> Void) {
        // Proユーザーの場合は広告を表示しない
        if SettingsManager.shared.isPremiumUser {
            onDismiss(false)
            return
        }

        guard let ad = self.rewardedAd else {
            print("⚠️ Rewarded ad not ready.")
            onDismiss(false)
            loadAd()
            return
        }
        
        self.adDismissalHandler = onDismiss
        self.rewardGranted = false
        
        ad.present(from: viewController) { [weak self] in
            print("ℹ️ Reward earned.")
            self?.rewardGranted = true
        }
    }
    
    // MARK: - GADFullScreenContentDelegate

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad did fail to present full screen content with error: \(error.localizedDescription)")
        adDismissalHandler?(false)
        rewardedAd = nil
        loadAd()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("ℹ️ Ad did dismiss full screen content.")
        // ✅ 解決策2: 完了処理を確実にメインスレッドで実行
        // このクラス全体が @MainActor なので、このデリゲートメソッドもメインスレッドで呼ばれることが保証されます。
        adDismissalHandler?(rewardGranted)
        
        rewardedAd = nil
        loadAd()
    }
}
