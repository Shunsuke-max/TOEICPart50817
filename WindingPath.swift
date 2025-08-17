import SwiftUI

/// 複数の点を滑らかなS字曲線で結ぶ、曲がりくねった道を描画するためのShape
struct WindingPath: Shape {
    var points: [CGPoint]
    var width: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }

        path.move(to: points[0])

        for i in 0..<points.count - 1 {
            let current = points[i]
            let next = points[i+1]

            // 制御点を計算して、より滑らかなS字カーブを描画
            let control1 = CGPoint(x: current.x, y: (current.y + next.y) / 2)
            let control2 = CGPoint(x: next.x, y: (current.y + next.y) / 2)

            path.addCurve(to: next, control1: control1, control2: control2)
        }
        
        return path.strokedPath(.init(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}
