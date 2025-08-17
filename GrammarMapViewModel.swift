
import Foundation
import SwiftUI

class GrammarMapViewModel: ObservableObject {
    @Published var clearedStages: Int = 0
    @Published var progress: Double = 0.0

    func loadProgress(for topic: GrammarTopic) {
        // Placeholder for loading progress
        // You'll need to implement the actual logic here
        self.clearedStages = 0 // Example value
        self.progress = 0.0 // Example value
    }

    func status(for stage: Stage) -> StageStatus {
        // Placeholder for determining stage status
        // You'll need to implement the actual logic here
        return .unlocked // Example value
    }
}


