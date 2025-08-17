import Foundation
import SwiftData

@Model
final class BookmarkedQuestion {
    // 同じ問題に重複してブックマークしないように、questionIDはユニーク（唯一）であるべき
    @Attribute(.unique) var questionID: String
    
    // いつブックマークされたかの日付
    var dateBookmarked: Date

    init(questionID: String, dateBookmarked: Date) {
        self.questionID = questionID
        self.dateBookmarked = dateBookmarked
    }
}
