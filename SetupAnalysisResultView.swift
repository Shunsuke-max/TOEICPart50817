import SwiftUI

private struct SetupAnalysisResultView: View {
    let recommendedCourse: Course?
    var onStartChallenge: () -> Void
    var onSkip: () -> Void
    
    @State private var showFirstChallenge = false
    @State private var firstQuestion: Question?
    
    var body: some View {
        VStack(spacing: 30) {
            if let course = recommendedCourse, let question = firstQuestion {
                // 分析完了後の表示
                Spacer()
                Image(systemName: "sparkles.and.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("分析完了！")
                    .font(.largeTitle.bold())
                
                VStack {
                    Text("あなたの弱点は...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("「\(course.courseName)」")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(course.courseColor)
                    Text("のようです。")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Text("まずは、このタイプの中から1問だけ挑戦して、学習の感覚を掴んでみましょう！")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("最初の1問に挑戦する") {
                    showFirstChallenge = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $showFirstChallenge, onDismiss: onStartChallenge) {
                    // ★QuizViewをシートで表示
                    NavigationView {
                        StandardQuizView(specialQuizSet: QuizSet(setId: "FIRST_CHALLENGE", setName: "最初の1問", questions: [question]), timeLimit: 20)
                    }
                }
                
                Button("あとでやる", action: onSkip)
                
            } else {
                // 弱点が見つからなかった、またはエラーの場合
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("素晴らしい！")
                    .font(.largeTitle.bold())
                Text("特に苦手な分野は見つかりませんでした。\n準備ができましたので、目標設定に進みましょう。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
                Button("目標設定に進む", action: onSkip)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(30)
        .task {
            // 表示される前に、おすすめコースから問題を1つ読み込んでおく
            if let course = recommendedCourse {
                self.firstQuestion = try? await DataService.shared.loadQuizSets(forCourse: course).first?.questions.randomElement()
            }
        }
    }
}
