
import SwiftUI

struct DrillStartButton: View {
    let isLoading: Bool
    let selectedLevelFileNames: Set<String>
    let prepareAndStartDrill: () async -> Void

    var body: some View {
        if isLoading {
            ProgressView()
        } else {
            Button(action: {
                Task {
                    await prepareAndStartDrill()
                }
            }) {
                Text("ドリル開始")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedLevelFileNames.isEmpty ? Color.gray.opacity(0.6).gradient : DesignSystem.Colors.brandPrimary.gradient)
                    .cornerRadius(DesignSystem.Elements.cornerRadius)
            }
            .disabled(selectedLevelFileNames.isEmpty)
        }
    }
}
