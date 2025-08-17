import SwiftUI

struct SyntaxSprintSetupView: View {
    @State private var selectedDifficulty: Int = 1 // 難易度
    @State private var selectedSkills: Set<String> = [] // スキル選択
    @State private var selectedGenres: Set<String> = [] // ジャンル選択
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    private let difficulties = [1, 2, 3] // 難易度オプション
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    private let skills = ["文法", "語彙"]
    private let genres = ["ビジネス", "日常会話", "時事"]

    // 難易度ごとの説明
    private func difficultyDescription(for level: Int) -> String {
        switch level {
        case 1: return "TOEIC 〜600点 / 3〜4個のチャンクで構成された短文"
        case 2: return "TOEIC 〜800点 /5〜6個のチャンクで構成された、少し複雑な文"
        case 3: return "TOEIC 800点〜 /7〜8個のチャンクで構成された、複雑な文"
        default: return ""
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    // --- モード説明セクション ---
                    VStack(spacing: 10) {
                        Image(systemName: "arrow.left.arrow.right.square") // アイコン変更
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.CourseAccent.blue)
                        Text("並び替えスプリント") // モード名変更
                            .font(.largeTitle.bold())
                        Text("バラバラになった文章を正しい語順に並び替え、文の構造を理解し、語順の感覚をマスターしよう！") // 説明文変更
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top)

                    // --- 設定項目 ---
                    VStack(alignment: .leading, spacing: 30) {
                        // --- 1. 難易度選択セクション ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text("1. 難易度を選択")
                                .font(.title2.bold())
                            
                            Picker("難易度", selection: $selectedDifficulty) {
                                ForEach(difficulties, id: \.self) { difficulty in
                                    Text("レベル \(difficulty)").tag(difficulty)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Text(difficultyDescription(for: selectedDifficulty)) // 動的な説明
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // --- 2. 集中したいスキルを選択（複数可） ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text("2. 集中したいスキルを選択（複数可）")
                                .font(.title2.bold())
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(skills, id: \.self) { skill in
                                    selectionCard(item: skill, selectedItems: $selectedSkills)
                                }
                            }
                            
                            HStack {
                                Button("すべて選択") { selectedSkills = Set(skills) }.buttonStyle(.bordered)
                                Button("すべて解除") { selectedSkills.removeAll() }.buttonStyle(.bordered)
                            }
                        }

                        // --- 3. 問題のジャンルを選択（複数可） ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text("3. 問題のジャンルを選択（複数可）")
                                .font(.title2.bold())
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(genres, id: \.self) { genre in
                                    selectionCard(item: genre, selectedItems: $selectedGenres)
                                }
                            }
                            
                            HStack {
                                Button("すべて選択") { selectedGenres = Set(genres) }.buttonStyle(.bordered)
                                Button("すべて解除") { selectedGenres.removeAll() }.buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    // --- 開始ボタン ---
                    startButton
                        .padding(.top, 20)
                }
                .padding()
            }
        }
        .navigationTitle("並び替えスプリント設定") // ナビゲーションタイトル変更
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            SyntaxSprintInfoSheet(
                onStartGame: { showInfoSheet = false },
                initialTime: SyntaxSprintViewModel.initialTime
            )
        }
    }
    
    @State private var showInfoSheet = false // 追加
    
    @ViewBuilder
    private func selectionCard(item: String, selectedItems: Binding<Set<String>>) -> some View {
        let isSelected = selectedItems.wrappedValue.contains(item)
        
        VStack(spacing: 8) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle") // チェックマークアイコン
                .font(.title)
                .foregroundColor(isSelected ? DesignSystem.Colors.CourseAccent.blue : .gray)
            
            Text(item)
                .font(.caption.bold())
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(.regularMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? DesignSystem.Colors.CourseAccent.blue : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if isSelected {
                    selectedItems.wrappedValue.remove(item)
                } else {
                    selectedItems.wrappedValue.insert(item)
                }
            }
        }
    }
    
    private var startButton: some View {
        NavigationLink(
            destination: SyntaxSprintView(
                difficulty: selectedDifficulty,
                skills: selectedSkills.map { $0 },
                genres: selectedGenres.map { $0 }
            )
        ) {
            Label("並び替えスプリント開始！", systemImage: "play.fill") // 文言変更
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    (selectedSkills.isEmpty || selectedGenres.isEmpty ? Color.gray : DesignSystem.Colors.CourseAccent.blue).gradient
                )
                .cornerRadius(16)
                .shadow(color: DesignSystem.Colors.CourseAccent.blue.opacity(selectedSkills.isEmpty || selectedGenres.isEmpty ? 0 : 0.4), radius: 8, y: 4)
        }
        .disabled(selectedSkills.isEmpty || selectedGenres.isEmpty)
        .simultaneousGesture(TapGesture().onEnded { })
    }

    @State private var showPaywall = false // Paywall表示用のStateを追加
}
