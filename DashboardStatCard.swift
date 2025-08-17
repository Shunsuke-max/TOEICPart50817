import SwiftUI

struct DashboardStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color // 値の色をカスタマイズできるように追加

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(color) // 引数で受け取った色を適用
                
                Text(unit)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(16) // 少し丸みを大きく
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2) // 影を少し調整
    }
}
