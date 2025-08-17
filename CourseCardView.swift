import SwiftUI

struct CourseCardView: View {
    let course: Course
    var isLocked: Bool = false
    var isRecommended: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: isLocked ? "lock.fill" : course.courseIcon)
                    .font(.title)
                    .foregroundColor(isLocked ? .gray : course.courseColor)
                
                VStack(alignment: .leading) {
                    Text(course.courseName)
                        .font(.headline.bold())
                        .foregroundColor(isLocked ? .gray : .primary)
                    
                    // ★★★ レッスン数と推定学習時間をまとめて表示 ★★★
                    HStack {
                        if let totalLessons = course.totalLessons {
                            Text("全 \(totalLessons) レッスン")
                                .font(.caption)
                                .foregroundColor(isLocked ? .gray : .secondary)
                        } else {
                            Text("全 \(course.quizSets.count) レッスン") // Fallback to quizSets.count
                                .font(.caption)
                                .foregroundColor(isLocked ? .gray : .secondary)
                        }
                        
                        if let estimatedTime = course.estimatedStudyTime {
                            Text("・約\(estimatedTime)分")
                                .font(.caption)
                                .foregroundColor(isLocked ? .gray : .secondary)
                        } else {
                            Text("・時間情報なし") // Placeholder
                                .font(.caption)
                                .foregroundColor(isLocked ? .gray : .secondary)
                        }
                    }
                }
                Spacer()
            }
            
            // ★★★ コース説明をここに移動 ★★★
            Text(course.courseDescription)
                .font(.caption)
                .foregroundColor(isLocked ? .gray : .secondary)
                .lineLimit(2)
            
            Spacer()
            
            // ★★★ タグをカードの下部に配置 ★★★
            if let tags = course.learningTags, !tags.isEmpty {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(isLocked ? Color.gray.opacity(0.1) : course.courseColor.opacity(0.2))
                            .cornerRadius(5)
                    }
                }
            } else {
                Text("タグ情報なし") // Placeholder
                    .font(.caption2)
                    .foregroundColor(isLocked ? .gray : .secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isLocked ? DesignSystem.Colors.surfacePrimary.opacity(0.5) : DesignSystem.Colors.surfacePrimary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isLocked ? Color.gray.opacity(0.3) : (isRecommended ? course.courseColor : Color.clear), lineWidth: isRecommended ? 3 : 1) // Stronger border for recommended
        )
        .shadow(color: isRecommended ? course.courseColor.opacity(0.6) : .clear, radius: isRecommended ? 10 : 0, x: 0, y: isRecommended ? 5 : 0) // Stronger shadow for recommended
        .overlay(alignment: .topTrailing) {
            if isRecommended {
                Text("あなたにおすすめ")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(LinearGradient(gradient: Gradient(colors: [.pink, .red]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(8)
                    .rotationEffect(.degrees(45))
                    .offset(x: 30, y: -10)
            }
        }
    }
}
