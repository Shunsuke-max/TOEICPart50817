import SwiftUI
import UniformTypeIdentifiers

struct ScramblePuzzleView: View {
    @ObservedObject var viewModel: SyntaxSprintViewModel
    let question: SyntaxScrambleQuestion
    
    // 解答が完了した際に、組み立てたチャンクを親Viewに通知するためのクロージャ
    let onAnswerSubmit: ([Chunk]) -> Void
    
    @Binding var assembledChunks: [Chunk]
    @State private var availableChunks: [Chunk] = []
    
    @Namespace private var chunkNamespace
    
    // ドラッグ中のチャンクを保持
    @State private var draggingChunk: Chunk? = nil

    // 各チャンクのフレーム情報を保持するState
    @State private var chunkFrames: [UUID: CGRect] = [:]

    var body: some View {
        VStack(spacing: 20) { // レイアウト調整
            // 問題文
            Text(question.questionText)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 組み立てエリア
            answerArea
                .padding(.horizontal)
                .onPreferenceChange(ChunkFramePreferenceKey.self) { preferences in
                    // 各チャンクのフレーム情報を収集
                    var newFrames: [UUID: CGRect] = [:]
                    for p in preferences {
                        newFrames[p.id] = p.frame
                    }
                    self.chunkFrames = newFrames
                }
            
            Divider()
            
            // チャンク選択エリア
            chunkBankArea
                .padding(.horizontal)
        }
        .onAppear(perform: setupChunks)
        // 新しい問題が渡されたら、チャンクをリセットして再設定する
        .onChange(of: question.id) {
            setupChunks()
        }
    }
    
    private func setupChunks() {
        availableChunks = question.chunks.shuffled()
    }
    
    private func selectChunk(_ chunk: Chunk) {
        if let index = availableChunks.firstIndex(where: { $0.id == chunk.id }) {
            let selected = availableChunks.remove(at: index)
            assembledChunks.append(selected)
        }
    }

    private func deselectChunk(_ chunk: Chunk) {
        if let index = assembledChunks.firstIndex(where: { $0.id == chunk.id }) {
            let deselected = assembledChunks.remove(at: index)
            availableChunks.append(deselected)
        }
    }
    
    // MARK: - Subviews
    
    private var answerArea: some View {
        ZStack(alignment: .topLeading) {
            // 点線のボックスで解答欄を表現
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.gray.opacity(0.5))
                .frame(minHeight: 120) // 高さを調整
            
            FlowLayout(alignment: .leading, spacing: 8) {
                ForEach(assembledChunks, id: \.id) { chunk in
                    chunkButton(chunk: chunk, isAssembled: true)
                        .matchedGeometryEffect(id: chunk.id, in: chunkNamespace)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(key: ChunkFramePreferenceKey.self, value: [ChunkFramePreferenceData(id: chunk.id, frame: geometry.frame(in: .named("answerArea")))])
                        })
                }
            }
            .coordinateSpace(name: "answerArea") // GeometryReaderの座標空間を定義
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            if assembledChunks.isEmpty {
                Text("ここにチャンクを並べてください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onDrop(of: [.plainText], delegate: ChunkDropDelegate(destinationChunks: $assembledChunks, sourceChunks: $availableChunks, onDrop: { _ in
            // ドロップが完了したら、解答を提出する
            if availableChunks.isEmpty {
                onAnswerSubmit(assembledChunks)
            }
        }, draggingChunk: $draggingChunk, chunkFrames: chunkFrames))
    }
    
    private var chunkBankArea: some View {
        ScrollView {
            FlowLayout(alignment: .center, spacing: 8) {
                ForEach(availableChunks, id: \.id) { chunk in
                    chunkButton(chunk: chunk, isAssembled: false)
                        .matchedGeometryEffect(id: chunk.id, in: chunkNamespace)
                }
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func chunkButton(chunk: Chunk, isAssembled: Bool) -> some View {
        Text(displayString(for: chunk, isAssembled: isAssembled))
            .font(.body.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isAssembled ? Color.green.opacity(0.2) : Color.blue.opacity(0.15)) // 色を調整
            .foregroundColor(.primary)
            .cornerRadius(8)
            .shadow(radius: 1)
            .opacity(draggingChunk?.id == chunk.id ? 0.0 : 1.0) // ドラッグ中は非表示
            .scaleEffect(draggingChunk?.id == chunk.id ? 1.1 : 1.0) // ドラッグ中は少し拡大
            .shadow(radius: draggingChunk?.id == chunk.id ? 5 : 1) // ドラッグ中は影を濃くする
            .onDrag { // ドラッグ可能にする
                self.draggingChunk = chunk
                return NSItemProvider(object: chunk.id.uuidString as NSString) // UUIDを文字列として渡す
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0) // minimumDistanceを0に設定してすぐにドラッグを開始
                    .onEnded { _ in
                        self.draggingChunk = nil
                    }
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    if isAssembled {
                        deselectChunk(chunk)
                    } else {
                        selectChunk(chunk)
                    }
                }
                HapticManager.mediumImpact()
            }
    }

    // チャンクの表示文字列を決定するヘルパー関数
    private func displayString(for chunk: Chunk, isAssembled: Bool) -> String {
        // "I" は常に大文字
        if chunk.text == "I" { return "I" }
        
        // 句読点（ピリオド、カンマ、疑問符、感嘆符）をチェック
        let punctuationMarks = Set([".", ",", "?", "!"])
        if punctuationMarks.contains(chunk.text) { return chunk.text }

        // チャンクの末尾がピリオドで終わる場合、表示からピリオドを除外
        var textToDisplay = chunk.text
        if textToDisplay.hasSuffix(".") {
            textToDisplay = String(textToDisplay.dropLast())
        }

        if isAssembled && assembledChunks.first?.id == chunk.id {
            // 組み立てられたチャンクの最初の要素のみ大文字にする
            return textToDisplay.capitalizedSentence
        } else {
            // それ以外のチャンクは小文字
            return textToDisplay.lowercased()
        }
    }
}

// Stringの拡張で、文頭を大文字にするヘルパーを追加
extension String {
    var capitalizedSentence: String {
        guard !isEmpty else { return "" }
        let firstChar = String(self.prefix(1)).uppercased()
        let otherChars = String(self.dropFirst()).lowercased()
        return firstChar + otherChars
    }
}

// 各チャンクのフレーム情報を保持するためのPreference Data
struct ChunkFramePreferenceData: Equatable {
    let id: UUID
    let frame: CGRect
}

// チャンクのフレーム情報を収集するためのPreferenceKey
struct ChunkFramePreferenceKey: PreferenceKey {
    static var defaultValue: [ChunkFramePreferenceData] = []

    static func reduce(value: inout [ChunkFramePreferenceData], nextValue: () -> [ChunkFramePreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

// ドロップデリゲート
struct ChunkDropDelegate: DropDelegate {
    @Binding var destinationChunks: [Chunk]
    @Binding var sourceChunks: [Chunk]
    var onDrop: (Chunk) -> Void
    @Binding var draggingChunk: Chunk? // ドラッグ中のチャンクを保持
    var chunkFrames: [UUID: CGRect] // 各チャンクのフレーム情報

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.plainText]).first else { return false }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, error) in
            if let idString = item as? String, let droppedUUID = UUID(uuidString: idString) {
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        var movedChunk: Chunk? = nil
                        var isFromSource = false

                        // Try to find the chunk in sourceChunks (availableChunks)
                        if let sourceIndex = sourceChunks.firstIndex(where: { $0.id == droppedUUID }) {
                            movedChunk = sourceChunks.remove(at: sourceIndex)
                            isFromSource = true
                        } 
                        // If not from source, try to find it in destinationChunks (assembledChunks) for reordering
                        else if let destIndex = destinationChunks.firstIndex(where: { $0.id == droppedUUID }) {
                            movedChunk = destinationChunks.remove(at: destIndex)
                            // isFromSource remains false, indicating reordering within destination
                        }

                        if let chunkToInsert = movedChunk {
                            let targetIndex = getTargetIndex(info: info)
                            destinationChunks.insert(chunkToInsert, at: targetIndex)
                            
                            if isFromSource {
                                // onDrop(chunkToInsert) // 自動提出ロジックを削除
                            }
                        }
                        self.draggingChunk = nil // Always reset after drop attempt
                    }
                }
            }
        }
        return true
    }

    func dropEntered(info: DropInfo) {
        // ドロップゾーンに入った時の処理（必要であれば）
    }

    func dropExited(info: DropInfo) {
        // ドロップゾーンから出た時の処理（ドラッグがキャンセルされた場合など）
        DispatchQueue.main.async {
            self.draggingChunk = nil // ドロップゾーンから出た時にdraggingChunkをリセット
        }
    }

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.plainText])
    }

    private func getTargetIndex(info: DropInfo) -> Int {
        let dropLocation = info.location
        var targetIndex = destinationChunks.count

        // Find the chunk closest to the drop location, considering both X and Y coordinates
        var closestChunkId: UUID? = nil
        var minDistance: CGFloat = .greatestFiniteMagnitude

        for (id, frame) in chunkFrames {
            let distance = CGPoint(x: frame.midX, y: frame.midY).distance(to: dropLocation)
            if distance < minDistance {
                minDistance = distance
                closestChunkId = id
            }
        }

        if let closestId = closestChunkId, let closestFrame = chunkFrames[closestId] {
            if let index = destinationChunks.firstIndex(where: { $0.id == closestId }) {
                // If dropping to the left half of the closest chunk, insert before it
                if dropLocation.x < closestFrame.midX {
                    targetIndex = index
                } else {
                    // If dropping to the right half, insert after it
                    targetIndex = index + 1
                }
            }
        }
        
        // Edge case: if dropping in empty space at the end of the last line
        // This is a simplified approach and might need further refinement for complex FlowLayouts
        if destinationChunks.isEmpty {
            targetIndex = 0
        } else if dropLocation.y > (chunkFrames.values.max(by: { $0.maxY < $1.maxY })?.maxY ?? 0) {
            targetIndex = destinationChunks.count
        }

        return targetIndex
    }
}

// Helper for CGPoint distance
extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx*dx + dy*dy)
    }
}





