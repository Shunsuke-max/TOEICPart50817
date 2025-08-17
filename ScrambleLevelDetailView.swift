import SwiftUI

/// 特定のレベルに含まれる並び替え問題の一覧を表示するView
struct ScrambleLevelDetailView: View {
    
    // 前の画面（マップ）から受け取る情報
    let level: Int
    let questions: [SyntaxScrambleQuestion]
    
    var body: some View {
        List {
            ForEach(questions) { question in
                NavigationLink(destination: SentenceScrambleView(question: question)) { 
                                    questionRow(for: question)
                                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
        .padding(.horizontal)
        .background(DesignSystem.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("レベル \(level) 問題一覧")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 各問題の行（カード）のUIを生成する
    @ViewBuilder
    private func questionRow(for question: SyntaxScrambleQuestion) -> some View {
        let isCompleted = ScrambleProgressManager.shared.isCompleted(id: question.id)
        
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("文法ポイント")
                    .font(.caption.bold())
                    .foregroundColor(color(forDifficulty: question.difficultyLevel))

                Text(question.explanation)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(DesignSystem.Elements.cornerRadius)
    }
    
    /// 難易度に応じて色を返すヘルパー関数
    private func color(forDifficulty level: Int) -> Color {
        switch level {
        case 1: return DesignSystem.Colors.CourseAccent.green
        case 2: return DesignSystem.Colors.CourseAccent.orange
        case 3: return DesignSystem.Colors.CourseAccent.red
        default: return .gray
        }
    }
}
