import SwiftUI

struct SentenceScrambleView: View {
    // MARK: - Properties
    
    // 外部から問題を受け取るためのプロパティ (エラー修正箇所)
    let question: SyntaxScrambleQuestion
    
    // このViewが内部で使うためのデータ形式に変換したもの (エラー修正箇所)
    private let questionChunks: [Chunk]
    
    // MARK: - State Variables
    
    @State private var sourceChunks: [Chunk]
    @State private var destinationChunks: [Chunk] = []
    @State private var draggingChunkID: UUID?
    @State private var dropTargetID: UUID?
    @State private var isCorrect: Bool?
    @State private var shakeAnswer: Int = 0
    @State private var chunkCorrectness: [UUID: Bool] = [:] // 各チャンクの正誤状態を保持
    @State private var hintUsed: Bool = false // ヒントが使用されたかどうか
    @State private var showCorrectAnswer: Bool = false // 正しい答えが表示されているかどうか
    
    // MARK: - Initializer
    
    init(question: SyntaxScrambleQuestion) {
        self.question = question
        self.questionChunks = question.chunks
        self._sourceChunks = State(initialValue: self.questionChunks.shuffled())
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("以下の単語を並び替えて、正しい文章を完成させてください。")
                    .font(.headline)
                    .padding(.horizontal)
                
                answerArea
                    .modifier(ShakeEffect(animatableData: CGFloat(shakeAnswer)))
                    .overlay {
                        if let isCorrect {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isCorrect ? .green : .red, lineWidth: 3)
                        }
                    }
                
                sourceArea
                
                Spacer()
                
                if let isCorrect {
                    Text(isCorrect ? "正解です！素晴らしい！" : "惜しい！もう一度試してみましょう。")
                        .font(.headline)
                        .foregroundColor(isCorrect ? .green : .red)
                        .padding()
                }
                
                HStack {
                    Button("リセット", role: .destructive) {
                        reset()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("ヒント") {
                        giveHint()
                    }
                    .buttonStyle(.bordered)
                    .disabled(hintUsed || !destinationChunks.isEmpty || isCorrect == true)
                    
                    Button("答え合わせ") {
                        checkAnswer()
                    }
                    .font(.title2.bold())
                    .buttonStyle(.borderedProminent)
                    .disabled(destinationChunks.isEmpty || isCorrect == true)
                    
                    if isCorrect == false {
                        Button("答えを見る") {
                            showAnswer()
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .padding()
                    }
                }
                        .padding()
                        .navigationTitle("並び替え問題")
                        .sensoryFeedback(.success, trigger: isCorrect) { oldValue, newValue in
                            return newValue == true
                        }
                        .sensoryFeedback(.error, trigger: isCorrect) { oldValue, newValue in
                            return newValue == false
                        }
                }
            }
        }
    
    // MARK: - View Components

    private var answerArea: some View {
        FlowLayout(alignment: .leading, spacing: 10) {
            if destinationChunks.isEmpty {
                // (この部分は変更なし)
                Rectangle()
                    .fill(.clear)
                    .frame(maxWidth: .infinity)
                    .dropDestination(for: Chunk.self) { droppedChunks, location in
                        guard let droppedChunk = droppedChunks.first else { return false }
                        if let sourceIndex = sourceChunks.firstIndex(where: { $0.id == droppedChunk.id }) {
                            sourceChunks.remove(at: sourceIndex)
                            destinationChunks.append(droppedChunk)
                        }
                        return true
                    }
            } else {
                ForEach(destinationChunks) { chunk in
                    Text(chunk.text)
                        .font(.headline)
                        .padding()
                        .background(backgroundColor(for: chunk))
                        .cornerRadius(10)
                        // ★★★ タップジェスチャーを追加 ★★★
                        .onTapGesture {
                            deselectChunk(chunk)
                        }
                        // ★★★ ここまで ★★★
                        .draggable(chunk) {
                                                    Text(chunk.text)
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .shadow(radius: draggingChunkID == chunk.id ? 8 : 3) // Increased shadow when dragging
                            .scaleEffect(draggingChunkID == chunk.id ? 1.05 : 1.0) // Slight scale effect
                            .onAppear { draggingChunkID = chunk.id }
                            .onDisappear { draggingChunkID = nil }
                        }
                        .opacity(draggingChunkID == chunk.id ? 0.5 : 1.0)
                        .dropDestination(for: Chunk.self) { droppedChunks, location in
                            guard let droppedChunk = droppedChunks.first, droppedChunk.id != chunk.id else {
                                return false
                            }
                            let sourceAreaIndex = sourceChunks.firstIndex(where: { $0.id == droppedChunk.id })
                            let destinationAreaIndex = destinationChunks.firstIndex(where: { $0.id == droppedChunk.id })
                            guard let targetIndex = destinationChunks.firstIndex(where: { $0.id == chunk.id }) else {
                                return false
                            }

                            if let sourceAreaIndex {
                                sourceChunks.remove(at: sourceAreaIndex)
                                destinationChunks.insert(droppedChunk, at: targetIndex + 1)
                            } else if let destinationAreaIndex {
                                let movedChunk = destinationChunks.remove(at: destinationAreaIndex)
                                destinationChunks.insert(movedChunk, at: targetIndex)
                            }
                            return true
                        } isTargeted: { isTargeted in
                            if isTargeted {
                                dropTargetID = chunk.id
                            } else if dropTargetID == chunk.id {
                                dropTargetID = nil
                            }
                        }
                        .overlay {
                            if dropTargetID == chunk.id {
                                RoundedRectangle(cornerRadius: 10).stroke(DesignSystem.Colors.brandPrimary, lineWidth: 3)
                            }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .sensoryFeedback(.success, trigger: destinationChunks.count)
    }
    
    private func backgroundColor(for chunk: Chunk) -> Color {
        guard let isCorrect = self.isCorrect else {
            return Color.blue.opacity(0.2) // 未判定時は通常の背景色
        }
        
        if isCorrect {
            return .green.opacity(0.2) // 全体正解時は緑
        } else {
            // 部分的な正誤判定に基づいて色を決定
            if let chunkIsCorrect = chunkCorrectness[chunk.id] {
                return chunkIsCorrect ? .green.opacity(0.2) : .red.opacity(0.2)
            } else {
                return Color.blue.opacity(0.2) // チャンクの正誤情報がない場合は通常の背景色
            }
        }
    }
    
    private var sourceArea: some View {
        FlowLayout(alignment: .center, spacing: 10) {
            ForEach(sourceChunks) { chunk in
                Text(chunk.text)
                    .font(.headline)
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
                    // ★★★ タップジェスチャーを追加 ★★★
                    .onTapGesture {
                        selectChunk(chunk)
                    }
                    // ★★★ ここまで ★★★
                    .draggable(chunk) {
                        Text(chunk.text)
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .shadow(radius: draggingChunkID == chunk.id ? 8 : 3)
                            .onAppear { draggingChunkID = chunk.id }
                            .onDisappear { draggingChunkID = nil }
                    }
                    .opacity(draggingChunkID == chunk.id ? 0.5 : 1.0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .padding()
        .dropDestination(for: Chunk.self) { droppedChunks, location in
            guard let droppedChunk = droppedChunks.first else { return false }
            if !sourceChunks.contains(where: { $0.id == droppedChunk.id }) {
                withAnimation(.spring()) {
                    destinationChunks.removeAll { $0.id == droppedChunk.id }
                    sourceChunks.append(droppedChunk)
                }
            }
            return true
        }
        .sensoryFeedback(.success, trigger: sourceChunks.count)
    }
    
    // MARK: - Private Methods
    
    private func handleDrop(droppedChunk: Chunk, targetID: UUID?) {
        let sourceAreaIndex = sourceChunks.firstIndex(where: { $0.id == droppedChunk.id })
        let destinationAreaIndex = destinationChunks.firstIndex(where: { $0.id == droppedChunk.id })

        withAnimation(.spring()) {
            if let sourceAreaIndex {
                sourceChunks.remove(at: sourceAreaIndex)
                if let targetID, let targetIndex = destinationChunks.firstIndex(where: { $0.id == targetID }) {
                    destinationChunks.insert(droppedChunk, at: targetIndex + 1)
                } else {
                    destinationChunks.append(droppedChunk)
                }
            } else if let destinationAreaIndex {
                let movedChunk = destinationChunks.remove(at: destinationAreaIndex)
                if let targetID, let targetIndex = destinationChunks.firstIndex(where: { $0.id == targetID }) {
                    let newIndex = destinationAreaIndex > targetIndex ? targetIndex + 1 : targetIndex
                    destinationChunks.insert(movedChunk, at: newIndex)
                } else {
                    destinationChunks.append(movedChunk)
                }
            }
        }
    }
    
    private func checkAnswer() {
        let userAnswerChunks = destinationChunks.map { $0.text }
        let correctAnswerChunks = self.question.chunks.map { $0.text }

        // 各チャンクの正誤判定をリセット
        chunkCorrectness = [:]

        // 全体の正誤判定
        isCorrect = (userAnswerChunks == correctAnswerChunks)

        // 各チャンクの正誤判定
        if isCorrect == false {
            for i in 0..<min(userAnswerChunks.count, correctAnswerChunks.count) {
                chunkCorrectness[destinationChunks[i].id] = (userAnswerChunks[i] == correctAnswerChunks[i])
            }
            // 余分なチャンクは不正解
            for i in correctAnswerChunks.count..<userAnswerChunks.count {
                chunkCorrectness[destinationChunks[i].id] = false
            }
        } else {
            // 全体正解の場合は全てtrue
            for chunk in destinationChunks {
                chunkCorrectness[chunk.id] = true
            }
        }

        if isCorrect == true {
            ScrambleProgressManager.shared.markAsCompleted(id: question.id)
            print("並び替え問題クリア！ ID: \(question.id)")
        } else {
            shakeAnswer += 1 // 不正解時にシェイク
        }
    }
    
    private func deselectChunk(_ chunk: Chunk) {
        withAnimation(.spring()) {
            if let index = destinationChunks.firstIndex(where: { $0.id == chunk.id }) {
                let deselectedChunk = destinationChunks.remove(at: index)
                sourceChunks.append(deselectedChunk)
                HapticManager.mediumImpact()
            }
        }
    }

    // 選択肢エリアのチャンクをタップした時の処理
    private func selectChunk(_ chunk: Chunk) {
        withAnimation(.spring()) {
            if let index = sourceChunks.firstIndex(where: { $0.id == chunk.id }) {
                let selectedChunk = sourceChunks.remove(at: index)
                destinationChunks.append(selectedChunk)
                HapticManager.mediumImpact()
            }
        }
    }

    private func reset() {
        withAnimation {
            sourceChunks = questionChunks.shuffled()
            destinationChunks = []
            isCorrect = nil
            chunkCorrectness = [:] // リセット時に正誤状態もクリア
            hintUsed = false // リセット時にヒント使用状態もクリア
            showCorrectAnswer = false // リセット時に答え表示状態もクリア
        }
    }
    
    private func giveHint() {
        guard !hintUsed, !question.chunks.isEmpty else { return }
        
        let firstCorrectChunk = question.chunks[0]
        
        if let indexInSource = sourceChunks.firstIndex(where: { $0.id == firstCorrectChunk.id }) {
            let chunkToMove = sourceChunks.remove(at: indexInSource)
            destinationChunks.insert(chunkToMove, at: 0)
            hintUsed = true
            HapticManager.mediumImpact()
        }
    }
    
    private func showAnswer() {
        withAnimation(.spring()) {
            destinationChunks = question.chunks // 正しい答えをセット
            sourceChunks = [] // ソースチャンクをクリア
            isCorrect = true // 正解状態にする
            showCorrectAnswer = true // 答えが表示されている状態にする
            chunkCorrectness = [:] // 正誤判定をリセット
            for chunk in destinationChunks {
                chunkCorrectness[chunk.id] = true // 全て正解としてマーク
            }
        }
    }
}

