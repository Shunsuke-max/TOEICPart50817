import SwiftUI

struct InformationSheetView: View {
    let content: String

    var body: some View {
        NavigationView {
            ScrollView {
                Text(content)
                    .padding()
            }
            .navigationTitle("情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        // Dismiss action will be handled by the parent view
                    }
                }
            }
        }
    }
}

struct InformationSheetView_Previews: PreviewProvider {
    static var previews: some View {
        InformationSheetView(content: "これはトレーニングに関する情報です。")
    }
}
