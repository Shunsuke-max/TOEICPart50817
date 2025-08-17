import SwiftUI


struct ScrambleMapView: View {
    let sections: [ScrambleSection]
    @StateObject private var progressManager = ScrambleProgressManager.shared
    
    // MARK: - Computed Properties
    
    private var totalQuestions: Int {
        sections.flatMap { $0.questions }.count
    }
    
    private var completedQuestions: Int {
        progressManager.completedIDs.count
    }
    
    private var progress: Double {
        totalQuestions > 0 ? Double(completedQuestions) / Double(totalQuestions) : 0
    }
    
    // MARK: - Layout Constants
    
    private let nodeVerticalSpacing: CGFloat = 100
    private let sectionHeaderHeight: CGFloat = 60
    private let initialYOffset: CGFloat = 50
    private let amplitude: CGFloat = 40
    private let frequency: CGFloat = 0.02
    
    // MARK: - Body
    
    var body: some View {
        let layout = calculateLayout()
        Group {
            LinearGradient(gradient: Gradient(colors: [
                Color(red: 0.7, green: 0.85, blue: 1.0), // Sky Blue
                Color(red: 0.6, green: 0.9, blue: 0.85)  // Sea Green
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            FloatingBubblesView()
            
            ZStack(alignment: .bottomTrailing) {
                ScrollViewReader { proxy in
                    ScrollView {
                        // MARK: Progress Bar
                        VStack {
                            HStack {
                                Text("学習進捗")
                                    .font(.headline)
                                Spacer()
                                Text("\(completedQuestions) / \(totalQuestions)")
                                    .font(.subheadline)
                            }
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.brandPrimary))
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .id("topOfMap") // Add id here
                        .background(Color.clear)
                        
                        // MARK: Map
                        ZStack {
                            // --- ここからが重要 ---
                            // 1. 【最背面のレイヤー】道を描画する
                            
                            // 1a. 全体をつなぐ「グレーの道」
                            Group {
                                if !layout.nodePoints.isEmpty {
                                    WindingPath(points: layout.nodePoints, width: 10)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 10)
                                }
                            }
                            
                            // 1b. クリア済み + 現在地までの「青い道」を上書き
                            let currentIndex = layout.items.firstIndex(where: { $0.isCurrent })
                            let lastCompletedIndex = layout.items.lastIndex(where: { $0.isComplete })
                            let progressEndIndex = currentIndex ?? lastCompletedIndex
                            
                            if let endIndex = progressEndIndex {
                                let progressPoints = Array(layout.nodePoints.prefix(endIndex + 1))
                                if progressPoints.count > 1 {
                                    // 影レイヤー
                                    WindingPath(points: progressPoints, width: 10)
                                        .stroke(DesignSystem.Colors.brandPrimary.opacity(0.5), lineWidth: 10)
                                        .blur(radius: 5)
                                        .offset(x: 0, y: 5)
                                    // 本体レイヤー
                                    WindingPath(points: progressPoints, width: 10)
                                        .stroke(DesignSystem.Colors.brandPrimary, lineWidth: 10)
                                }
                            }
                            
                            // 2. 【中間のレイヤー】ヘッダーテキストを描画する
                            ForEach(layout.items, id: \.id) { item in
                                if let headerInfo = item.headerInfo {
                                    VStack(alignment: .leading) {
                                        Text(headerInfo.theme)
                                            .font(.title2.bold())
                                        Text(headerInfo.subtitle)
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    // ここで背景色を指定しない、もしくは .clear にする
                                    // .background(Color.clear)
                                    .position(headerInfo.position)
                                }
                            }
                            
                            // 3. 【最前面のレイヤー】ノードを描画する
                            ForEach(layout.items, id: \.id) { item in
                                NavigationLink(destination: ScrambleSessionView(questions: item.section.questions)) {
                                    LevelNodeView(
                                        level: (item.question as SyntaxScrambleQuestion).difficultyLevel,
                                        isLocked: item.isLocked,
                                        isComplete: item.isComplete,
                                        isCurrent: item.isCurrent
                                    )
                                }
                                .disabled(item.isLocked)
                                .position(item.nodePoint)
                                .id(item.id) // Add id here
                                .background(Color.clear) // <-- これを追加
                                .buttonStyle(PlainButtonStyle()) // <-- これを追加
                            }
                        }
                        .frame(height: layout.totalHeight)
                        .background(Color.clear)
                    }
                    .background(Color.clear)
                    .onAppear {
                        progressManager.objectWillChange.send() // 強制的にUI更新を促す
                        
                        // Find the target item to scroll to
                        if let currentItem = layout.items.first(where: { $0.isCurrent }) {
                            proxy.scrollTo(currentItem.id, anchor: .center)
                        } else if let lastCompletedItem = layout.items.last(where: { $0.isComplete }) {
                            proxy.scrollTo(lastCompletedItem.id, anchor: .center)
                        } else if let firstItem = layout.items.first { // Fallback to the very first item if nothing is current or completed
                            proxy.scrollTo(firstItem.id, anchor: .center)
                        }
                    }
                    // スクロールに追従する「トップへ移動」ボタン
                    Button {
                        proxy.scrollTo("topOfMap", anchor: .top)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(DesignSystem.Colors.brandPrimary)
                            .shadow(radius: 5)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Layout Calculation
    
    private struct MapLayout {
        let items: [MapItem]
        let nodePoints: [CGPoint]
        let totalHeight: CGFloat
    }
    
    private struct MapItem: Identifiable {
        let id: String
        let question: SyntaxScrambleQuestion
        let nodePoint: CGPoint
        let isLocked: Bool
        let isComplete: Bool
        let isCurrent: Bool
        var headerInfo: HeaderInfo?
        let section: ScrambleSection // 新しく追加
        
        struct HeaderInfo {
            let theme: String
            let subtitle: String
            let position: CGPoint
        }
    }
    
    private func calculateLayout() -> MapLayout {
        var items: [MapItem] = []
        var nodePoints: [CGPoint] = []
        var yPos: CGFloat = initialYOffset
        let centerX = UIScreen.main.bounds.width / 2
        
        for section in sections {
            for (qIndex, question) in section.questions.enumerated() {
                // Header position for the first question of a section
                var headerInfo: MapItem.HeaderInfo?
                if qIndex == 0 {
                    let headerPosition = CGPoint(x: centerX, y: yPos)
                    headerInfo = .init(theme: section.theme, subtitle: section.subtitle, position: headerPosition)
                    yPos += sectionHeaderHeight
                }
                
                // Node position
                let xOffset = sin(yPos * frequency) * amplitude
                let nodePoint = CGPoint(x: centerX + xOffset, y: yPos)
                nodePoints.append(nodePoint)
                print("Node Point: x=\(nodePoint.x), y=\(nodePoint.y)")
                
                // State calculation
                let isComplete = progressManager.isCompleted(id: question.id)
                var isLocked = true // Assume locked by default
                var isCurrent = false // Will be set later
                
                // Find the previous question in the flattened list of all questions
                let allQuestionsFlat = sections.flatMap { $0.questions }
                let currentIndex = allQuestionsFlat.firstIndex(where: { $0.id == question.id }) ?? 0
                
                print("--- Debugging Unlock Logic for Question: \(question.id) ---")
                print("  isComplete (current): \(isComplete)")
                print("  currentIndex: \(currentIndex)")
                
                if currentIndex == 0 { // The very first question is always unlocked
                    isLocked = false
                    print("  Result: First question, isLocked = false")
                } else {
                    let previousQuestion = allQuestionsFlat[currentIndex - 1]
                    let isPreviousCompleted = progressManager.isCompleted(id: previousQuestion.id)
                    print("  Previous Question ID: \(previousQuestion.id)")
                    print("  isCompleted (previous): \(isPreviousCompleted)")
                    
                    if isPreviousCompleted {
                        isLocked = false
                        isLocked = false
                    } else {
                        // isLocked remains true
                    }
                }
                
                // Determine isCurrent based on the new isLocked and isComplete
                isCurrent = !isComplete && !isLocked
                
                
                let mapItem = MapItem(
                    id: question.id,
                    question: question,
                    nodePoint: nodePoint,
                    isLocked: isLocked,
                    isComplete: isComplete,
                    isCurrent: isCurrent,
                    headerInfo: headerInfo,
                    section: section // ここでsectionを渡す
                )
                items.append(mapItem)
                
                yPos += nodeVerticalSpacing
            }
        }
        
        
        return MapLayout(items: items, nodePoints: nodePoints, totalHeight: yPos)
    }
}
