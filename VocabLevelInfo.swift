import SwiftUI

/// 各レベルの情報を保持するためのシンプルな構造体
struct VocabLevelInfo: Identifiable {
    let id = UUID()
    let level: String
    let description: String
    let jsonFileName: String
    let color: Color
    let icon: String
    let isProFeature: Bool // 追加
}

struct VocabularyLevelSelectionView: View {

    // 表示するレベルのリスト
    private let levels: [VocabLevelInfo] = [
        .init(level: "600点コース", description: "TOEICの基礎となる必須単語", jsonFileName: "course_vocab_600.json", color: DesignSystem.Colors.CourseAccent.blue, icon: "1.circle.fill", isProFeature: false),
        // 今後、新しいJSONファイルを追加する際に、このリストに追加するだけで拡張可能
        .init(level: "730点コース", description: "スコアアップの鍵となる重要単語", jsonFileName: "course_vocab_730.json", color: DesignSystem.Colors.CourseAccent.orange, icon: "2.circle.fill", isProFeature: false),
        .init(level: "860点コース", description: "差がつく応用・派生単語", jsonFileName: "course_vocab_860.json", color: DesignSystem.Colors.CourseAccent.blue, icon: "3.circle.fill", isProFeature: true),
        .init(level: "990点コース", description: "満点を目指すための超上級単語", jsonFileName: "course_vocab_990.json", color: DesignSystem.Colors.CourseAccent.purple, icon: "4.circle.fill", isProFeature: true)
    ]

    var body: some View {
        List {
            ForEach(levels) { levelInfo in
                // 次の画面（クイズセット一覧）にファイル名を渡して遷移
                NavigationLink(destination: VocabularyQuizSetSelectionView(
                    levelName: levelInfo.level,
                    vocabJsonFileName: levelInfo.jsonFileName, color: levelInfo.color
                )) {
                    levelRow(for: levelInfo)
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.vertical, 6)
        }
        .listStyle(.plain)
        .padding(.horizontal)
        .background(DesignSystem.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("語彙レベル選択")
        .navigationBarTitleDisplayMode(.large)
    }

    /// 各レベルの行の見た目を定義
    private func levelRow(for levelInfo: VocabLevelInfo) -> some View {
        HStack(spacing: 16) {
            Image(systemName: levelInfo.icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 55, height: 55)
                .background(levelInfo.color)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 5) {
                Text(levelInfo.level)
                    .font(DesignSystem.Fonts.headline)
                    .fontWeight(.bold)
                Text(levelInfo.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
    }
}

struct VocabularyLevelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VocabularyLevelSelectionView()
        }
    }
}
