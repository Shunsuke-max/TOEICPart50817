
import SwiftUI

struct ErrorMessageView: View {
    let errorMessage: String?

    var body: some View {
        if let errorMessage = errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
        }
    }
}
