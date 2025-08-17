import SwiftUI

struct CourseProgressHeaderView: View {
    let completedCount: Int
    let totalCount: Int
    
    private var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text(courseName) を削除
            
            HStack {
                Text("コース達成度: \(completedCount) / \(totalCount)") // 結合
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.headline.bold()) // パーセンテージを少し強調
                    .foregroundColor(DesignSystem.Colors.brandPrimary)
            }
            
            ProgressView(value: progress)
                .tint(DesignSystem.Colors.brandPrimary.gradient)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                .animation(.easeInOut, value: progress)
        }
        .padding()
    }
}
