
import SwiftUI

struct LevelTitleView: View {
    let level: VocabLevelInfo

    var body: some View {
        HStack {
            Text(level.level).font(.headline)
            if level.isProFeature {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("Pro")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
}
