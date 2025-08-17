import SwiftUI

struct TimeAttackSetupView: View {
    @State private var courses: [Course] = []
    @State private var selectedCourseIDs: Set<String> = []
    @State private var isLoading = true
    @State private var selectedMistakeLimit: Int = 5
    @Environment(\.dismiss) private var dismiss
    
    private let mistakeLimitOptions = [0, 3, 5, 10]
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    @StateObject private var navigationManager = TimeAttackNavigationManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) { // 間隔を広げる
                    if isLoading {
                        ProgressView("レベル別コース一覧を読み込み中...")
                            .padding(.top, 100)
                    } else {
                        // --- 提案1: ルール説明セクション ---
                        VStack(spacing: 10) {
                            Image(systemName: "timer")
                                .font(.system(size: 60))
                                .foregroundColor(DesignSystem.Colors.CourseAccent.red)
                            Text("5分間で限界に挑戦！")
                                .font(.largeTitle.bold())
                            Text("時間内に何問正解できるかを測定します。")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)

                        // --- 提案3: ステップ形式のUI ---
                        VStack(alignment: .leading, spacing: 30) {
                            // --- 1. コース選択セクション ---
                            VStack(alignment: .leading, spacing: 16) {
                                Text("1. 出題範囲を選択")
                                    .font(.title2.bold())
                                
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(courses) { course in
                                        courseSelectionCard(for: course)
                                    }
                                }
                                
                                HStack {
                                    Button("すべて選択") { selectAll() }.buttonStyle(.bordered)
                                    Button("すべて解除") { deselectAll() }.buttonStyle(.bordered)
                                }
                            }
                            
                            // --- 2. ルール設定セクション ---
                            VStack(alignment: .leading, spacing: 10) { // 間隔を調整
                                Text("2. ミス許容回数を設定")
                                    .font(.title2.bold())
                                
                                Picker("ミス許容回数", selection: $selectedMistakeLimit) {
                                    ForEach(mistakeLimitOptions, id: \.self) { limit in
                                        if limit == 0 {
                                            Text("上限なし").tag(0)
                                        } else {
                                            Text("\(limit) 回まで").tag(limit)
                                        }
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                // --- 補足説明 ---
                                Text("選択した回数ミスをすると、その時点でチャレンジ終了となります。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // --- 開始ボタンをScrollView内に移動 ---
                        startButton
                            .padding(.top, 20) // 上部に少し余白を追加
                    }
                }
                .padding()
            }
            
        }
        .navigationTitle("タイムアタック設定")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCourses()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func courseSelectionCard(for course: Course) -> some View {
        let isSelected = selectedCourseIDs.contains(course.id)
        
        VStack(spacing: 12) {
            Image(systemName: course.courseIcon)
                .font(.largeTitle)
                .foregroundColor(course.courseColor)
            
            Text(course.courseName)
                .font(.caption.bold())
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(.regularMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? course.courseColor : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                toggleSelection(for: course.id)
            }
        }
    }
    
    private var startButton: some View {
        NavigationLink(
            destination: TimeAttackContainerView(
                selectedCourseIDs: selectedCourseIDs,
                mistakeLimit: selectedMistakeLimit,
            ),
            isActive: $navigationManager.isLinkActive
        ){
            Label("タイムアタック開始！", systemImage: "bolt.fill") // 文言を調整
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    (selectedCourseIDs.isEmpty ? Color.gray : DesignSystem.Colors.CourseAccent.red).gradient
                )
                .cornerRadius(16)
                .shadow(color: .red.opacity(selectedCourseIDs.isEmpty ? 0 : 0.4), radius: 8, y: 4)
        }
        .disabled(selectedCourseIDs.isEmpty)
    }
    
    // MARK: - Private Methods
    private func toggleSelection(for courseID: String) {
        if selectedCourseIDs.contains(courseID) {
            selectedCourseIDs.remove(courseID)
        } else {
            selectedCourseIDs.insert(courseID)
        }
    }

    private func selectAll() {
        selectedCourseIDs = Set(courses.map { $0.id })
    }

    private func deselectAll() {
        selectedCourseIDs.removeAll()
    }
    
    private func loadCourses() async {
        guard courses.isEmpty else { return }
        do {
            let loadedCourses = try await DataService.shared.loadCourseManifest()
            self.courses = loadedCourses
            self.isLoading = false
        } catch {
            print("コースマニフェストの読み込みに失敗: \(error)")
            self.isLoading = false
        }
    }
}
