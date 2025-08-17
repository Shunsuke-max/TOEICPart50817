
import SwiftUI

struct QuestionCountSelectionView: View {
    @Binding var selectedQuestionCount: Int
    let questionCountOptions: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("2. 問題数を選択")
                .font(.headline)
            
            Picker("問題数", selection: $selectedQuestionCount) {
                ForEach(questionCountOptions, id: \.self) { count in
                    Text("\(count)問").tag(count)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
