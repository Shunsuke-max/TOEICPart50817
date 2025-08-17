import Foundation
import UIKit

/// メールの作成と送信をサポートするヘルパー
enum MailHelper {
    
    /// `mailto`のURLを生成します。
    /// - Parameters:
    ///   - to: 宛先のメールアドレス
    ///   - subject: 件名
    ///   - body: 本文
    /// - Returns: 生成されたURL。失敗した場合はnil。
    static func createMailUrl(to: String, subject: String, body: String) -> URL? {
        // アプリ名、バージョン、ビルド番号、iOSバージョンを自動で取得
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "App"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let osVersion = UIDevice.current.systemVersion

        // 本文のテンプレートを作成
        let bodyTemplate = """
        \(body)


        --------------------------------
        【自動で挿入される情報】
        アプリ名: \(appName)
        バージョン: \(appVersion) (\(appBuild))
        OS: iOS \(osVersion)
        --------------------------------
        """
        
        // 件名と本文をURLで安全に使えるようにエンコード
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = bodyTemplate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoString = "mailto:\(to)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        return URL(string: mailtoString)
    }
}
