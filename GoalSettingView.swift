import SwiftUI

struct GoalSettingView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 現在選択されている目標時間を保持する（分単位）
    var onComplete: (() -> Void)? = nil
    @State private var selectedGoalInMinutes: Int
    @State private var showPicker = false // ピッカーの表示/非表示を制御
    
    // 選択可能な目標時間（分単位）
    private let cardOptions: [(minutes: Int, description: String)] = [
        (10, "通勤・通学中にサクッと"),
        (20, "毎日コツコツ"),
        (30, "集中して取り組む"),
        (45, "本気でスコアアップ"),
        (60, "がっつり学習"),
    ]
    
    private let pickerOptions: [Int] = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 90, 120]

    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
        let currentGoalInSeconds = SettingsManager.shared.dailyGoal
        _selectedGoalInMinutes = State(initialValue: Int(currentGoalInSeconds / 60))
    }

    var body: some View {
        ZStack {
            AuroraBackgroundView(colors: [DesignSystem.Colors.brandPrimary.opacity(0.3), .blue.opacity(0.3)])
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("毎日の学習を習慣にしよう！")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("目標設定が、スコアアップの第一歩です。")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineLimit(nil)
                    
                    Spacer()
                    
                    // カード形式の選択肢
                    VStack(spacing: 15) {
                        ForEach(cardOptions, id: \.minutes) { option in
                            Button(action: {
                                selectedGoalInMinutes = option.minutes
                                showPicker = false
                            }) {
                                HStack {
                                    Text("\(option.minutes) 分")
                                        .font(.title2.bold())
                                    Spacer()
                                    Text(option.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(nil)
                                }
                                .padding()
                                .background(selectedGoalInMinutes == option.minutes ? DesignSystem.Colors.brandPrimary.opacity(0.2) : DesignSystem.Colors.surfacePrimary)
                                .cornerRadius(DesignSystem.Elements.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Elements.cornerRadius)
                                        .stroke(selectedGoalInMinutes == option.minutes ? DesignSystem.Colors.brandPrimary : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // その他の時間ボタン
                        Button(action: {
                            showPicker.toggle()
                        }) {
                            HStack {
                                Text("その他の時間")
                                    .font(.title2.bold())
                                Spacer()
                                Image(systemName: showPicker ? "chevron.up" : "chevron.down")
                            }
                            .padding()
                            .background(showPicker ? DesignSystem.Colors.brandPrimary.opacity(0.2) : DesignSystem.Colors.surfacePrimary)
                            .cornerRadius(DesignSystem.Elements.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Elements.cornerRadius)
                                    .stroke(showPicker ? DesignSystem.Colors.brandPrimary : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // ピッカー
                    if showPicker {
                        Picker("目標時間", selection: $selectedGoalInMinutes) {
                            ForEach(pickerOptions, id: \.self) {
                                Text("\($0) 分").tag($0)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 150)
                        .clipped()
                    }
                    
                    // フィードバック
                    Text("毎日\(selectedGoalInMinutes)分続ければ、1ヶ月で約\(selectedGoalInMinutes * 30)分、\(String(format: "%.1f", Double(selectedGoalInMinutes * 30) / 60.0))時間の学習になります！")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    Button("保存する") {
                        saveAndDismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Spacer()
                }
                .frame(maxWidth: 500)
                .padding()
                .frame(maxWidth: .infinity) // .infinityを使ってVStackを中央に配置
                .background(.ultraThinMaterial)
                .cornerRadius(DesignSystem.Elements.cornerRadius)
                .padding()
            }
            .navigationTitle("目標設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveAndDismiss() {
        let newGoalInSeconds = TimeInterval(selectedGoalInMinutes * 60)
        SettingsManager.shared.dailyGoal = newGoalInSeconds
        
        // ★★★ onCompleteクロージャを呼び出すか、なければdismissする ★★★
        if let onComplete = onComplete {
            onComplete()
        } else {
            dismiss()
        }
    }
}
