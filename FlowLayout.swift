import SwiftUI

struct FlowLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0
        var lineWidth: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if lineWidth + size.width + spacing > maxWidth {
                height += rowHeight
                rowHeight = 0
                lineWidth = 0
            }
            lineWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        let maxWidth = bounds.width
        var rowHeight: CGFloat = 0
        var rowSubviews: [LayoutSubviews.Element] = []

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if origin.x + size.width + spacing > bounds.maxX {
                // 新しい行に移動する前に、現在の行のアイテムを中央揃えで配置
                let totalWidth = rowSubviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width } + spacing * CGFloat(rowSubviews.count - 1)
                var startX = bounds.origin.x
                if alignment == .center {
                    startX += (maxWidth - totalWidth) / 2
                } else if alignment == .trailing {
                    startX += maxWidth - totalWidth
                }
                
                var currentX = startX
                for rowView in rowSubviews {
                    let rowViewSize = rowView.sizeThatFits(.unspecified)
                    rowView.place(at: CGPoint(x: currentX, y: origin.y), anchor: .topLeading, proposal: .unspecified)
                    currentX += rowViewSize.width + spacing
                }
                
                // 次の行へ
                origin.y += rowHeight + spacing
                rowHeight = 0
                origin.x = bounds.origin.x
                rowSubviews.removeAll()
            }
            rowSubviews.append(view)
            rowHeight = max(rowHeight, size.height)
            origin.x += size.width + spacing
        }
        
        // 最後の行の配置
        let totalWidth = rowSubviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width } + spacing * CGFloat(rowSubviews.count - 1)
        var startX = bounds.origin.x
        if alignment == .center {
            startX += (maxWidth - totalWidth) / 2
        } else if alignment == .trailing {
            startX += maxWidth - totalWidth
        }

        var currentX = startX
        for rowView in rowSubviews {
            let rowViewSize = rowView.sizeThatFits(.unspecified)
            rowView.place(at: CGPoint(x: currentX, y: origin.y), anchor: .topLeading, proposal: .unspecified)
            currentX += rowViewSize.width + spacing
        }
    }
}
