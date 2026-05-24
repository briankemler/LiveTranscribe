import SwiftUI

/// Lightweight flowing wrap layout for chip rows. SwiftUI's built-in `WrappingHStack` doesn't exist
/// pre-iOS 16 and the iOS 16+ `Layout` API is what we use here.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        var anyOnRow = false

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            let needed = (anyOnRow ? spacing : 0) + size.width
            if rowWidth + needed > maxWidth, anyOnRow {
                totalHeight += rowHeight + lineSpacing
                rowWidth = size.width
                rowHeight = size.height
                anyOnRow = true
            } else {
                rowWidth += needed
                rowHeight = max(rowHeight, size.height)
                anyOnRow = true
            }
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        var anyOnRow = false

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            let needed = (anyOnRow ? spacing : 0) + size.width
            if x + needed > bounds.maxX, anyOnRow {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
                anyOnRow = false
            }
            if anyOnRow { x += spacing }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width
            rowHeight = max(rowHeight, size.height)
            anyOnRow = true
        }
    }
}
