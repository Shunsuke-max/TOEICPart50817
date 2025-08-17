import SwiftUI

/// 文法トピックの学習マップを表示する画面
struct QuizSectionMapView: View {
    let topic: QuizSection
    @ObservedObject var viewModel: QuizMapViewModel
    
    var body: some View {
        ZStack {
            // 背景
            AuroraBackgroundView(colors: [
                topic.color.opacity(0.9),
                topic.color.opacity(0.6),
                topic.color.opacity(0.4)
            ])
            .ignoresSafeArea()
            
            // メインコンテンツ
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    topicHeader
                    
                    // プログレスバー
                    progressBar
                    
                    // ステージ一覧
                    stagesView
                }
                .padding()
            }
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadProgress(for: topic)
        }
    }
    
    // MARK: - Subviews
    
    private var topicHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: topic.iconName)
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
            Text(topic.description)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    private var progressBar: some View {
        VStack {
            HStack {
                Text("進捗")
                Spacer()
                Text("\(viewModel.clearedStages) / \(topic.levels.count)")
            }
            .font(.caption.bold())
            .foregroundColor(.white)
            
            ProgressView(value: viewModel.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(x: 1, y: 4, anchor: .center) // Increased thickness
        }
        .padding(.horizontal)
    }
    
    private var stagesView: some View {
        let nodePoints = topic.levels.enumerated().map { (index, stage) -> CGPoint in
            let yOffset = CGFloat(index) * 120 + 100 // Reduced vertical space
            let xOffset = CGFloat(sin(Double(index) * 0.5) * 50) + UIScreen.main.bounds.width / 2 // S-curve
            return CGPoint(x: xOffset, y: yOffset)
        }

        return ZStack {
            if nodePoints.count > 1 {
                WindingPath(points: nodePoints, width: 10)
                    .stroke(Color.white.opacity(0.7), lineWidth: 10)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
            }
            
            VStack(spacing: 80) { // Reduced spacing
                ForEach(Array(topic.levels.enumerated()), id: \.offset) { index, stage in
                    let status = viewModel.status(for: stage)
                    
                    NavigationLink(destination: QuizContainerView(quizSetId: stage.quizSetId)) {
                        QuizLevelNodeView(level: stage, status: status)
                    }
                    .disabled(status == .locked)
                    .position(nodePoints[index])
                }
            }
            .frame(height: CGFloat(topic.levels.count) * 120 + 200) // Adjust frame height
        }
    }
}

