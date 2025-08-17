import SwiftUI

@MainActor
class ScrambleReviewViewModel: ObservableObject {
    @Published var reviewQuestions: [SyntaxScrambleQuestion] = []
    @Published var isLoading = true
    @Published var error: Error?
    
    private let fileName = "syntax_scramble_vol1.json"
    private let reviewQuestionCount = 5

    func prepareReviewSession() async {
        self.isLoading = true
        self.error = nil
        
        do {
            let allQuestions = try await DataService.shared.loadSyntaxScrambleSet(from: fileName).syntaxScrambleQuestions
            
            // ★ ScrambleProgressManagerの新しいメソッドを呼び出す
            let completedIDs = ScrambleProgressManager.shared.getCompletedIDs()
            
            let completedQuestions = allQuestions.filter { completedIDs.contains($0.id) }
            
            if completedQuestions.count >= reviewQuestionCount {
                self.reviewQuestions = Array(completedQuestions.shuffled().prefix(reviewQuestionCount))
            } else {
                self.reviewQuestions = completedQuestions.shuffled()
            }
            
        } catch {
            self.error = error
        }
        
        self.isLoading = false
    }
}
