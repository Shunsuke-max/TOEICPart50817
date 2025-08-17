
import SwiftUI

struct SelectAllButton: View {
    @Binding var selectedLevelFileNames: Set<String>
    let levels: [VocabLevelInfo]
    let isPremiumUser: Bool

    var body: some View {
        Button(action: {
            withAnimation {
                if selectedLevelFileNames.count == levels.count {
                    // すべて選択されている場合はすべて解除
                    selectedLevelFileNames.removeAll()
                } else {
                    // Proユーザーであれば全てのレベルを選択、そうでなければPro版ではないレベルのみを選択
                    let selectableLevels = isPremiumUser ? levels : levels.filter { !$0.isProFeature }
                    selectedLevelFileNames = Set(selectableLevels.map { $0.jsonFileName })
                }
            }
        }) {
            Text(selectedLevelFileNames.count == levels.count ? "すべて解除" : "すべて選択")
                .font(.subheadline)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(DesignSystem.Colors.brandPrimary)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding(.bottom, 8)
    }
}
