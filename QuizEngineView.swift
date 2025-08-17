import SwiftUI

/// 1問分のクイズUIを表示することに責務を持つView
struct QuizEngineView: View {
    
    @ObservedObject var viewModel: QuizEngineViewModel
    @State private var showExplanationSheet = false
    @State private var showCorrectAnimation = false // 新しく追加
    let onSelectOption: (Int) -> Void // ★★★ 変更
    let onNextQuestion: () -> Void
    let onBookmark: (() async -> Void)?
    let isBookmarked: Bool?
    let shouldShowCorrectAnimation: Bool
    let isTimeAttackMode: Bool
    
    init(
        viewModel: QuizEngineViewModel,
        onSelectOption: @escaping (Int) -> Void, // ★★★ 変更
        onNextQuestion: @escaping () -> Void,
        onBookmark: (() async -> Void)? = nil,
        isBookmarked: Bool? = nil,
        shouldShowCorrectAnimation: Bool = true,
        isTimeAttackMode: Bool = false
    ) {
        self.viewModel = viewModel
        self.onSelectOption = onSelectOption // ★★★ 変更
        self.onNextQuestion = onNextQuestion
        self.onBookmark = onBookmark
        self.isBookmarked = isBookmarked
        self.shouldShowCorrectAnimation = shouldShowCorrectAnimation
        self.isTimeAttackMode = isTimeAttackMode
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    // ★★★ ここからが修正箇所 ★★★
                    HStack(alignment: .top, spacing: 8) {
                        // 問題文
                        Text(viewModel.question.questionText)
                            .font(.title3.bold()) // フォントサイズを少し調整
                            .lineSpacing(8) // 行間を広げる
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // if let onBookmark, let isBookmarked {
                        //     Button(action: {
                        //         Task {
                        //             await onBookmark()
                        //         }
                        //     }) {
                        //         Image(systemName: isBookmarked ? "star.fill" : "star")
                        //             .font(.title2)
                        //             .foregroundColor(.yellow)
                        //     }
                        // }
                    }
                    .padding(.horizontal, 8)
                    
                    // 選択肢
                    OptionsListView(
                        options: viewModel.question.options,
                        selectedAnswerIndex: viewModel.selectedAnswerIndex,
                        correctAnswerIndex: viewModel.question.correctAnswerIndex,
                        isSubmitted: viewModel.isAnswerSubmitted,
                        onSelect: onSelectOption, // ★★★ 変更
                        shouldShowCorrectAnimation: shouldShowCorrectAnimation,
                        isAnswerLocked: viewModel.isAnswerLocked
                    )
                    
                    // 解答後のフィードバック
                    if viewModel.isAnswerSubmitted {
                        feedbackContent
                            .transition(.opacity.animation(.easeInOut))
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
                .id("quizTop") // スクロール用ID
            }
            .onChange(of: viewModel.isAnswerSubmitted) {
                if viewModel.isAnswerSubmitted {
                    withAnimation {
                        // 解説が表示されたら一番下にスクロールする
                        proxy.scrollTo("feedbackAnchor", anchor: .bottom)
                    }
                    // 正解時にアニメーションをトリガー
                    if viewModel.isCorrect == true {
                        showCorrectAnimation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1秒後にアニメーションをリセット
                            showCorrectAnimation = false
                        }
                    }
                } else {
                    // 新しい問題になったら一番上にスクロールする
                    proxy.scrollTo("quizTop", anchor: .top)
                }
            }
            // 正解時の大きな丸のアニメーションをオーバーレイとして追加
            .overlay(alignment: .center) {
                if shouldShowCorrectAnimation && showCorrectAnimation { // 条件を追加
                    Circle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 200, height: 200)
                        .scaleEffect(showCorrectAnimation ? 1.0 : 0.1)
                        .opacity(showCorrectAnimation ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCorrectAnimation)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.white)
                                .scaleEffect(showCorrectAnimation ? 1.0 : 0.1)
                                .opacity(showCorrectAnimation ? 1.0 : 0.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: showCorrectAnimation)
                        )
                }
            }
        }
    }
    
    /// 解説や復習ボタンを表示するエリア
    private var feedbackContent: some View {
        VStack(spacing: 15) {
            // isCorrectがnilでないことを確認
            if shouldShowCorrectAnimation, let isCorrect = viewModel.isCorrect { // 条件を追加
                Text(isCorrect ? "正解！" : "不正解")
                    .font(.title.bold())
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            // タイムアタックモードでない場合のみボタンを表示
            HStack {
                if !isTimeAttackMode { // 解説を見るボタンのみ制御
                    Button(action: { showExplanationSheet = true }) {
                        Label("解説を見る", systemImage: "questionmark.circle")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer() // ボタンが一つだけの場合に中央に寄らないようにSpacerを追加

                Button(action: onNextQuestion) {
                    Text("次へ進む")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
                        
                        Color.clear.frame(height: 1).id("feedbackAnchor")
                    }
                    .sheet(isPresented: $showExplanationSheet) {
                        explanationSheet
                    }
                }
    
    /// 解説をシートで表示するための部品
    private var explanationSheet: some View {
        NavigationView {
            // ★★★ このVStackの中身を全面的に修正 ★★★
            VStack(spacing: 0) {
                // --- ヘッダー ---
                HStack {
                    Text("解説")
                        .font(.headline)
                    Spacer()
                    Button("閉じる") {
                        showExplanationSheet = false
                    }
                }
                .padding()
                .background(.thinMaterial)

                Divider()
                
                // --- コンテンツ本体 ---
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 問題文
                        Text("Q. \(viewModel.question.questionText)")
                            .font(.title2.bold())
                        
                        Divider()
                        
                        // 選択肢一覧
                        ForEach(viewModel.question.options.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Image(systemName: index == viewModel.question.correctAnswerIndex ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(index == viewModel.question.correctAnswerIndex ? .green : .secondary)
                                Text(viewModel.question.options[index])
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        
                        Divider()
                        
                        // 解説文
                        Text("解説")
                            .font(.headline)
                        Text(viewModel.question.explanation)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationBarHidden(true) // NavigationViewのデフォルトタイトルは不要なため隠す
        }
    }
    
    
    // MARK: - Reusable Nested UI Components
    
    // 元々QuizViewにあった選択肢リストのUIをこちらに移動
    private struct OptionsListView: View {
        let options: [String]
        let selectedAnswerIndex: Int?
        let correctAnswerIndex: Int
        let isSubmitted: Bool
        let onSelect: (Int) -> Void
        let shouldShowCorrectAnimation: Bool // 追加
        let isAnswerLocked: Bool // 追加
        
        var body: some View {
            VStack(spacing: 12) {
                ForEach(0..<options.count, id: \.self) { index in
                    Button(action: { onSelect(index) }) {
                        HStack {
                            Text(String(format: "%c", 65 + index))
                            Text(options[index])
                            Spacer()
                        }
                    }
                    .buttonStyle(OptionButtonStyle(
                        isSubmitted: isSubmitted,
                        isSelected: index == selectedAnswerIndex,
                        isCorrect: index == correctAnswerIndex,
                        shouldShowCorrectAnimation: shouldShowCorrectAnimation
                    ))
                    .disabled(isAnswerLocked)
                }
            }
        }
    }
    
    // 元々QuizViewにあった選択肢ボタンのスタイルをこちらに移動
    private struct OptionButtonStyle: ButtonStyle {
        let isSubmitted: Bool
        let isSelected: Bool
        let isCorrect: Bool
        let shouldShowCorrectAnimation: Bool // 追加
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundColor)
                .foregroundColor(.primary)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
        
        private var backgroundColor: Color {
            // shouldShowCorrectAnimationがfalseの場合は、正解/不正解の色分けをしない
            if !shouldShowCorrectAnimation {
                return isSelected ? .blue.opacity(0.7) : DesignSystem.Colors.surfacePrimary
            }
            
            guard isSubmitted else { return DesignSystem.Colors.surfacePrimary }
            if isCorrect { return .green.opacity(0.7) }
            if isSelected { return .red.opacity(0.6) }
            return DesignSystem.Colors.surfacePrimary
        }
    }
}
