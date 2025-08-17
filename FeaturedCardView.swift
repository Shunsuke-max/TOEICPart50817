import SwiftUI

struct FeaturedCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
                .frame(width: 50)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.title2.weight(.bold)) // Changed to bold
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(20)
    }
}
