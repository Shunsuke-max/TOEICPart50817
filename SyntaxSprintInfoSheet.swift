import SwiftUI

struct SyntaxSprintInfoSheet: View {
    var onStartGame: () -> Void
    let initialTime: Double // Add this property
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("ゲームのルール")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 10)
                    
                    InfoSection(title: "制限時間", descriptions: [
                        "初期持ち時間は\(Int(initialTime))秒です。",
                        "1問正解するごとに4秒追加されます。",
                        "不正解の場合は2秒引かれます。（同時にコンボもリセットされます）",
                        "コンボが続くほど、1問正解あたりの獲得タイムが増加します。",
                        "  • 1～9コンボ: +4秒 (基本タイム)",
                        "  • 10～29コンボ: +5秒 (基本+4秒 + コンボボーナス+1秒）",
                        "  • 30コンボ以上: +6秒 (基本+4秒 + コンボボーナス+2秒）"
                    ])

                    InfoSection(title: "文頭の文字", descriptions: [
                        "✅ The → the （文頭でも小文字に）",
                        "❌ John → John （固有名詞はそのまま）"
                    ])

                    InfoSection(title: "ピリオドの扱い", descriptions: [
                        "✅ 文末のピリオドは自動で付きます。"
                    ])

                    InfoSection(title: "「I」の扱い", descriptions: [
                        "✅ 一人称単数代名詞の「I」は、常に大文字で表示されます。"
                    ])

                    InfoSection(title: "ペナルティ", descriptions: [
                        "ヒントを使用すると5秒、パスすると5秒のペナルティが発生します。"
                    ])

                    Spacer()
                    
                    Button("理解した！") {
                        onStartGame()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("ゲームのルール")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true) // 標準の戻るボタンを非表示
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { // 左側に閉じるボタンを配置
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct InfoSection: View {
    let title: String
    let descriptions: [String] // Changed to array of String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())
            ForEach(descriptions, id: \.self) { desc in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
