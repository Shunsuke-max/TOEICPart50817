import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    // ★★★ メールURLを開くためのEnvironmentプロパティを追加 ★★★
    @Environment(\.openURL) private var openURL

    @State private var selectedDuration: Int
    @EnvironmentObject private var storeManager: StoreManager
    @State private var isPremiumUser: Bool = SettingsManager.shared.isPremiumUser
    @State private var isReminderEnabled: Bool
    @State private var reminderDate: Date
    // --- FIX 1: Add the type annotation ': Bool' ---
    @State private var isNewMockTestNotificationEnabled: Bool
    @State private var areSoundEffectsEnabled: Bool
    @State private var isBGMEnabled: Bool // 新しく追加

    private let durationOptions = [10, 20, 30, 60]
    private let timerOffValue = SettingsManager.shared.timerOffValue

    init() {
        _selectedDuration = State(initialValue: SettingsManager.shared.timerDuration)
        _isReminderEnabled = State(initialValue: SettingsManager.shared.isReminderEnabled)
        _isNewMockTestNotificationEnabled = State(initialValue: SettingsManager.shared.isNewMockTestNotificationEnabled)
        _areSoundEffectsEnabled = State(initialValue: SettingsManager.shared.areSoundEffectsEnabled)
        _isBGMEnabled = State(initialValue: SettingsManager.shared.isBGMEnabled)

        // --- FIX 2: Correctly initialize reminderDate ---
        // Get the saved time components from SettingsManager
        let reminderComponents = SettingsManager.shared.reminderTime
        // Create a Date object from those components for today's date
        let date = Calendar.current.date(from: reminderComponents) ?? Date()
        _reminderDate = State(initialValue: date)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("サウンド")) {
                    Toggle("効果音を再生する", isOn: $areSoundEffectsEnabled)
                    Toggle("BGMを再生する", isOn: $isBGMEnabled)
                }
                
                // ... The rest of your body code is correct ...
                // (I've omitted it for brevity, but no changes are needed here)
                 Section(header: Text("クイズの制限時間")) {
                    Picker("時間を選択", selection: $selectedDuration) {
                        Text("タイマーなし").tag(timerOffValue)
                        ForEach(durationOptions, id: \.self) { duration in
                            Text("\(duration) 秒").tag(duration)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section(header: Text("プレミアム機能")) {
                    if isPremiumUser {
                        HStack {
                            Text("購入済み")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        Button("広告をすべて削除（買い切り）") {
                            Task {
                                if let product = storeManager.products.first {
                                    try? await storeManager.purchase(product)
                                }
                            }
                        }
                    }

                    Button("購入情報を復元する") {
                        Task {
                            try? await storeManager.restorePurchases()
                        }
                    }
                    if isPremiumUser {
                        Toggle("新しい模試の公開時に通知", isOn: $isNewMockTestNotificationEnabled)
                    }
                }
                Section(header: Text("学習リマインダー")) {
                    Toggle("リマインダー通知", isOn: $isReminderEnabled)

                    if isReminderEnabled {
                        DatePicker(
                            "通知時間",
                            selection: $reminderDate,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section(header: Text("サポート")) {
                    Button {
                        // 宛先や件名を指定してメールURLを生成
                        guard let url = MailHelper.createMailUrl(
                            to: "shunsuke7377@icloud.com", // Remember to change this to your support email
                            subject: "【TOEIC Part5 トレーナー】お問い合わせ",
                            body: "ここに内容をご記入ください。"
                        ) else {
                            print("メールURLの作成に失敗しました。")
                            return
                        }
                        // URLを開いてメールアプリを起動
                        openURL(url)

                    } label: {
                        Label("ご意見・ご要望を送る", systemImage: "paperplane.fill")
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        SettingsManager.shared.timerDuration = selectedDuration
                        SettingsManager.shared.isReminderEnabled = isReminderEnabled
                        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
                        SettingsManager.shared.reminderTime = components
                        SettingsManager.shared.isNewMockTestNotificationEnabled = isNewMockTestNotificationEnabled

                        MockTestManager.shared.scheduleNewSetReminder()
                        SettingsManager.shared.areSoundEffectsEnabled = areSoundEffectsEnabled
                        SettingsManager.shared.isBGMEnabled = isBGMEnabled

                        dismiss()
                    }
                }
            }
            .task {
                await storeManager.fetchProducts()
            }
            .onChange(of: storeManager.purchasedProductIDs) {
                self.isPremiumUser = !storeManager.purchasedProductIDs.isEmpty
            }
        }
    }
}
