import Foundation
import SwiftData

@Model
class ReviewItem {
    var id: UUID
    var questionID: String
    var lastReviewed: Date
    var nextReview: Date
    var repetition: Int // 復習回数
    var easeFactor: Double // 復習間隔を調整するための要素 (SM-2アルゴリズムなど)
    var lastInterval: TimeInterval // 追加: 前回の復習間隔 (秒)

    init(id: UUID = UUID(), questionID: String, lastReviewed: Date, nextReview: Date, repetition: Int, easeFactor: Double, lastInterval: TimeInterval = 0) {
        self.id = id
        self.questionID = questionID
        self.lastReviewed = lastReviewed
        self.nextReview = nextReview
        self.repetition = repetition
        self.easeFactor = easeFactor
        self.lastInterval = lastInterval
    }
}