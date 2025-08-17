import Foundation
import SwiftData
import Combine
import AVFoundation

// Viewでアニメーションを扱うため、ChunkをIdentifiableに準拠させたラッパー
struct ChunkItem: Identifiable, Equatable {
    let id = UUID()
    let chunk: Chunk
    
    var text: String { chunk.text }
    var syntaxRole: String? { chunk.syntaxRole }
}

@MainActor
class ScrambleQuizViewModel: ObservableObject {
    
    private let correctChunks: [Chunk]
    let explanation: String
    
    @Published var availableChunks: [ChunkItem] = []
    @Published var assembledChunks: [ChunkItem] = []
    @Published var isAnswerChecked: Bool = false
    @Published var isCorrect: Bool = false
    @Published var shakeAnswer: Int = 0
    @Published var isCompleted = false
    
    // 音声合成用のシンセサイザー
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let reviewManager: ReviewManager = ReviewManager()
    private var modelContext: ModelContext! // Implicitly Unwrapped Optionalに変更
    
    // 正解の文章を生成するコンピューテッドプロパティ
    var correctSentence: String {
        correctChunks.map { $0.text }.joined(separator: " ")
    }
    
    init(question: SyntaxScrambleQuestion) { // modelContextをinitから削除
        self.correctChunks = question.chunks
        self.explanation = question.explanation
        self.reset()
    }
    
    // modelContextを設定するメソッドを追加
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// 選択肢バンクのチャンクを解答欄に移動する
    func selectChunk(_ chunkItem: ChunkItem) async {
        guard !isAnswerChecked else { return }
        if let index = availableChunks.firstIndex(where: { $0.id == chunkItem.id }) {
            let selected = availableChunks.remove(at: index)
            assembledChunks.append(selected)
            
            // 最後のチャンクが置かれたら、自動で答え合わせを実行
            if availableChunks.isEmpty {
                await checkAnswer()
            }
        }
    }
    
    /// 解答欄のチャンクを選択肢バンクに戻す
    func deselectChunk(_ chunkItem: ChunkItem) {
        guard !isAnswerChecked else { return }
        if let index = assembledChunks.firstIndex(of: chunkItem) {
            let deselected = assembledChunks.remove(at: index)
            availableChunks.append(deselected)
        }
    }
    
    /// 組み立てられた文章の正誤を判定する
    private func checkAnswer() async {
        let userAnswerTextArray = assembledChunks.map { $0.text }
        let correctAnswerTextArray = correctChunks.map { $0.text }
        
        isCorrect = (userAnswerTextArray == correctAnswerTextArray)
        isAnswerChecked = true
        
        // 問題IDは、SyntaxScrambleQuestionのIDを使用
        let questionID = correctChunks.first?.id.uuidString ?? UUID().uuidString // 適切なIDを取得

        if isCorrect {
            // 正解した場合
            HapticManager.shared.playSuccess()
            speakSentence() // 正解文を読み上げる
            ScrambleProgressManager.shared.markAsCompleted(id: questionID)
            await reviewManager.updateReviewItem(questionID: questionID, quality: 5, modelContext: modelContext)
        } else {
            // 不正解だった場合
            HapticManager.shared.playError()
            shakeAnswer += 1 // シェイクアニメーションを発動
            await reviewManager.updateReviewItem(questionID: questionID, quality: 0, modelContext: modelContext)
            
            // 1秒後にチャンクをリセットして再挑戦できるようにする
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isAnswerChecked = false // 再度操作可能にする
                // 解答欄のチャンクを選択肢バンクに戻す
                self.availableChunks.append(contentsOf: self.assembledChunks)
                self.assembledChunks.removeAll()
                self.availableChunks.shuffle() // 戻した後に再度シャッフル
            }
        }
    }
    
    /// クイズの状態を初期状態に戻す
    func reset() {
        isAnswerChecked = false
        isCorrect = false
        assembledChunks.removeAll()
        availableChunks = correctChunks.shuffled().map { ChunkItem(chunk: $0) }
    }
    
    /// ヒント機能：次の正しいチャンクを一つだけ解答欄に移動する
    func provideHint() async {
        guard !isAnswerChecked, !availableChunks.isEmpty else { return }
        
        let nextCorrectChunkIndex = assembledChunks.count
        guard nextCorrectChunkIndex < correctChunks.count else { return }
        
        let nextCorrectChunk = correctChunks[nextCorrectChunkIndex]
        
        if let hintChunkIndex = availableChunks.firstIndex(where: { $0.chunk.text == nextCorrectChunk.text }) {
            let chunkToMove = availableChunks.remove(at: hintChunkIndex)
            assembledChunks.append(chunkToMove)
            
            // ヒントを使った結果、全てのチャンクが揃ったら答え合わせ
            if availableChunks.isEmpty {
                await checkAnswer()
            }
        }
    }
    
    /// 答えを見る機能：全てのチャンクを正しい順序で解答欄に配置する
    func revealAnswer() async {
        guard !isAnswerChecked else { return }
        
        // 全てのチャンクを正しい順序で並べ替える
        assembledChunks = correctChunks.map { chunk in
            (availableChunks + assembledChunks).first { $0.chunk.text == chunk.text }!
        }
        availableChunks.removeAll()
        
        // 答え合わせを実行
        isCorrect = true
        isAnswerChecked = true
        speakSentence()
        
        // 答えを見た場合も不正解として記録
        let questionID = correctChunks.first?.id.uuidString ?? UUID().uuidString // 適切なIDを取得
        await reviewManager.updateReviewItem(questionID: questionID, quality: 0, modelContext: modelContext)
    }
    
    /// 完成した英文を読み上げる
    func speakSentence() {
        let utterance = AVSpeechUtterance(string: correctSentence)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        speechSynthesizer.speak(utterance)
    }
    
    func completeQuiz() {
        isCompleted = true
    }
}
