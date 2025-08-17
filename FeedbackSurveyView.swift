import SwiftUI

/// 「役に立ちましたか？」を問うマイクロサーベイのView
struct FeedbackSurveyView: View {
    
    /// 評価対象のクイズセットID
    let quizSetId: String
    
    /// このViewを非表示にするためのアクション
    var onDismiss: () -> Void
    
    @State private var didSubmit = false

    var body: some View {
        VStack(spacing: 12) {
            Text("このクイズセットは役に立ちましたか？")
                .font(.headline)
            
            HStack(spacing: 20) {
                Button {
                    submit(wasHelpful: true)
                } label: {
                    Label("はい", systemImage: "hand.thumbsup.fill")
                }
                .buttonStyle(.bordered)
                .tint(.green)
                
                Button {
                    submit(wasHelpful: false)
                } label: {
                    Label("いいえ", systemImage: "hand.thumbsdown.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity)
        .transition(.opacity.animation(.easeInOut))
        // didSubmitがtrueになったら、少し待ってからViewを閉じる
        .onChange(of: didSubmit) {
            if didSubmit {
                // 0.5秒後に非表示にする
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss()
                }
            }
        }
        .overlay {
            // 送信完了時に「ありがとうございます！」と表示
            if didSubmit {
                Text("ありがとうございます！")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .transition(.opacity.animation(.easeInOut))
            }
        }
    }
    
    private func submit(wasHelpful: Bool) {
        FeedbackManager.shared.submitQuizSetFeedback(quizSetId: quizSetId, wasHelpful: wasHelpful)
        didSubmit = true
    }
}
