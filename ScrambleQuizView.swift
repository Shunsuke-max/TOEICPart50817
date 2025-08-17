import SwiftUI

struct ScrambleQuizView: View {
    @StateObject private var viewModel: ScrambleQuizViewModel
    let onComplete: ((Bool) async -> Void)?
    let currentIndex: Int // 現在の問題のインデックス
    let totalQuestions: Int // 全問題数
    @Namespace private var chunkNamespace
    @Environment(\.modelContext) var modelContext
    
    // アニメーションとフィードバック用のState
    @State private var showSuccessOverlay = false
    
    init(question: SyntaxScrambleQuestion, currentIndex: Int, totalQuestions: Int, onComplete: ((Bool) async -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ScrambleQuizViewModel(question: question))
        self.currentIndex = currentIndex
        self.totalQuestions = totalQuestions
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 進捗表示
                Text("\(currentIndex + 1) / \(totalQuestions)")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                headerButtons
                    .padding()
                
                answerArea
                    .modifier(ShakeEffect(animatableData: CGFloat(viewModel.shakeAnswer)))
                    .padding(.horizontal)
                
                Divider().padding()
                
                chunkBankArea
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            
            // 正解時のお祝いオーバーレイ
            if showSuccessOverlay {
                successOverlay
            }
        }
        .navigationTitle("並び替えモード")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isCorrect) {
            if viewModel.isCorrect {
                // 正解したら、少し遅れてオーバーレイを表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { showSuccessOverlay = true }
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
    
    // MARK: - Subviews

    private var headerButtons: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    await viewModel.provideHint()
                }
            } label: {
                Label("ヒント", systemImage: "lightbulb.fill")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isAnswerChecked)

            Button("答えを見る") {
                Task {
                    await viewModel.revealAnswer()
                    withAnimation {
                        showSuccessOverlay = true // 答えを見たらオーバーレイを表示
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .disabled(viewModel.isAnswerChecked)
        }
    }
    
    private var answerArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .frame(minHeight: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.isAnswerChecked ? (viewModel.isCorrect ? .green : .red) : Color(.systemGray4), lineWidth: 2)
                        .padding(1)
                )
            
            if viewModel.assembledChunks.isEmpty {
                Text("ここにチャンクを並べてください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.vertical) {
                FlowLayout(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.assembledChunks) { chunk in
                        chunkButton(chunk: chunk, isAssembled: true)
                    }
                }
                .padding()
            }
            .frame(minHeight: 150)
        }
    }
    
    private var chunkBankArea: some View {
        ScrollView {
            FlowLayout(alignment: .center, spacing: 12) {
                ForEach(viewModel.availableChunks) { chunk in
                    chunkButton(chunk: chunk, isAssembled: false)
                }
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func chunkButton(chunk: ChunkItem, isAssembled: Bool) -> some View {
        ZStack(alignment: .top) {
            Button(action: {
                Task { // ここをTaskでラップ
                    await handleChunkSelection(chunk: chunk, isAssembled: isAssembled)
                }
            }) {
                Text(processedChunkText(chunk))
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(viewModel.isCorrect && isAssembled ? Color.green.opacity(0.2) : Color.blue.opacity(0.15))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    .animation(.easeInOut, value: viewModel.isCorrect)
            }
            .buttonStyle(.plain)
            .matchedGeometryEffect(id: chunk.id, in: chunkNamespace)
            .disabled(viewModel.isAnswerChecked)
            
            // 正解後に構文役割ラベルを表示
            if viewModel.isCorrect && isAssembled {
                Text(chunk.syntaxRole ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.green).shadow(radius: 2))
                    .offset(y: -10)
                    .transition(.scale.animation(.spring()))
            }
        }
        .padding(.top, 10)
    }
    
    private func handleChunkSelection(chunk: ChunkItem, isAssembled: Bool) async {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if isAssembled {
                viewModel.deselectChunk(chunk)
            } else {
                // selectChunkはasyncなので、awaitが必要
                Task { @MainActor in // ここもTaskでラップし、MainActorを指定
                    await viewModel.selectChunk(chunk)
                }
            }
        }
        HapticManager.mediumImpact()
    }

    private func processedChunkText(_ chunk: ChunkItem) -> String {
        // 正解している場合のみ、元の正しい大文字・小文字表記を返す
        if viewModel.isCorrect {
            return chunk.text
        }
        // 挑戦中は、すべて小文字で表示する
        return chunk.text.lowercased()
    }

    private func handleNextButtonAction() {
        Task { @MainActor in // ここを修正
            showSuccessOverlay = false
            if let completeAction = onComplete {
                await completeAction(viewModel.isCorrect)
            }
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { 
                    withAnimation { 
                        showSuccessOverlay = false 
                    }
                }
            
            ConfettiView()
            
            VStack(spacing: 20) {
                Text("Excellent!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(viewModel.explanation)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(16)
                
                Button(action: { handleNextButtonAction() }) {
                    Text("次へ")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(20)
                }
            }
            .padding(30)
        }
    }
}

// MARK: - ShakeEffect

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}
