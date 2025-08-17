import Foundation

class StudyTimeManager {
    // アプリ内で常に同じインスタンスを利用するためのシングルトン
    static let shared = StudyTimeManager()

    // UserDefaultsにデータを保存するためのキー
    private let studyTimeKey = "totalStudyTimeKey"
    private let dailyStudyRecordsKey = "dailyStudyRecordsKey" // ★★★ 追加 ★★★

    // 外部からのインスタンス化を防ぐ
    private init() {}

    /// 指定された学習時間を合計に加算して保存します。
    /// - Parameter time: 追加する学習時間（秒単位のTimeInterval）
    func add(time: TimeInterval) {
        let currentTotal = getTotalStudyTime()
        let newTotal = currentTotal + time
        UserDefaults.standard.set(newTotal, forKey: studyTimeKey)
        
        // ★★★ 日ごとの学習記録を更新 ★★★
        var dailyRecords = getDailyStudyRecords()
        let today = Date().formattedDateString()
        dailyRecords[today, default: 0] += time
        UserDefaults.standard.set(dailyRecords, forKey: dailyStudyRecordsKey)
    }

    /// 保存されている合計学習時間を取得します。
    /// - Returns: 合計学習時間（秒単位）
    func getTotalStudyTime() -> TimeInterval {
        // キーが存在しない場合は 0.0 が返る
        return UserDefaults.standard.double(forKey: studyTimeKey)
    }
    
    /// 保存されている合計学習時間を、人間が読みやすい形式（例：「1時間23分」）の文字列に変換して返します。
    /// - Returns: フォーマットされた学習時間の文字列
    func formattedTotalStudyTime() -> String {
        let totalSeconds = getTotalStudyTime()

        if totalSeconds < 1 {
            return "学習記録なし"
        }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full // 例: "1 hour, 10 minutes" -> 日本語環境では「1時間10分」
        formatter.allowedUnits = [.hour, .minute] // 時間と分のみ表示（秒は切り捨て）
        formatter.maximumUnitCount = 2 // 表示する単位の最大数
        
        // 1分未満の場合は「1分未満」と表示する
        if totalSeconds < 60 {
            return "1分未満"
        }

        return formatter.string(from: totalSeconds) ?? "0分"
    }
    
    // ★★★ 日ごとの学習記録を取得 ★★★
    func getDailyStudyRecords() -> [String: TimeInterval] {
        UserDefaults.standard.dictionary(forKey: dailyStudyRecordsKey) as? [String: TimeInterval] ?? [:]
    }
    
    // ★★★ 指定された月の学習時間を集計 ★★★
    func getMonthlyStudyTime(year: Int, month: Int) -> TimeInterval {
        let records = getDailyStudyRecords()
        let calendar = Calendar.current
        
        return records.filter { (dateString, _) in
            guard let date = Date.fromFormattedString(dateString) else { return false }
            let components = calendar.dateComponents([.year, .month], from: date)
            return components.year == year && components.month == month
        }.values.reduce(0, +)
    }
    
    // ★★★ 指定された年の学習時間を集計 ★★★
    func getYearlyStudyTime(year: Int) -> TimeInterval {
        let records = getDailyStudyRecords()
        let calendar = Calendar.current
        
        return records.filter { (dateString, _) in
            guard let date = Date.fromFormattedString(dateString) else { return false }
            let components = calendar.dateComponents([.year], from: date)
            return components.year == year
        }.values.reduce(0, +)
    }
}

extension Date {
    func formattedDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    static func fromFormattedString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}
