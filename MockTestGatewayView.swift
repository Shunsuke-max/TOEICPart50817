import SwiftUI

struct MockTestGatewayView: View {
    let testInfo: MockTestInfo

    @State private var availability: MockTestManager.Availability?
    
    var body: some View {
        VStack {
            if let availability = availability {
                switch availability {
                case .available:
                    // ★★★ 新しいinitに合わせて修正 ★★★
                    MockTestStartView(testInfo: testInfo)
                    
                case .inProgress(let session):
                    if session.testSetId == "MOCK_TEST_WEEK_1" {
                        MockTestStartView(testInfo: testInfo)
                    } else {
                        Text("挑戦中の模試があります。")
                    }

                case .onCooldown(let remaining):
                    // (クールダウン画面の実装)
                    Text("クールダウン中です。")

                case .proUserOnly:
                    // (ペイウォール画面の実装)
                    Text("Proユーザー限定です。")
                }
            } else {
                ProgressView("受験資格を確認中...")
            }
        }
        .task {
            self.availability = MockTestManager.shared.getAvailabilityState(for: testInfo.setId)
        }
        .navigationTitle(testInfo.setName)
    }
}
