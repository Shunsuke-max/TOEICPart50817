
import SwiftUI

struct AppUsageSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("アプリの使い方")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 10)

                    UsageSection(title: "はじめに", content: ["アプリの目的と概要、主要なタブの紹介。"])
                    UsageSection(title: "ホーム画面", content: ["予測スコア、学習目標、デイリーミッション、学習記録について。"])
                    UsageSection(title: "コース", content: ["コースの種類、進め方、アンロック条件。"])
                    UsageSection(title: "トレーニング", content: ["各トレーニングモードの基本ルールと特徴。"])
                    UsageSection(title: "成績分析", content: ["学習時間、正解率、苦手傾向の確認方法。"])
                    UsageSection(title: "設定・その他", content: ["学習目標、通知、プレミアム機能、お問い合わせ。"])
                }
                .padding()
            }
            .navigationTitle("アプリの使い方")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct UsageSection: View {
    let title: String
    let content: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.primary)
            ForEach(content, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text(item)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
