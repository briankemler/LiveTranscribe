import SwiftUI

/// The V6 "Bubble Icon" brand mark, recreated in SwiftUI for in-app reuse.
/// Mirrors `icon-export/ic_launcher_full.svg`: peach-gradient speech bubble with
/// glow halo and three knock-out caption lines, on the warm near-black ground.
/// The shape uses a 100×100 design grid (same as the SVG path); pass any `size`
/// and everything scales together.
struct BubbleMark: View {
    var size: CGFloat = 96
    /// Whether to render the dark `#0e0b08` ground behind the bubble. Off when used inline.
    var showGround: Bool = false
    /// Whether to apply the iOS-style squircle clip (for launch / splash hero use).
    var cornerRadius: CGFloat? = nil

    var body: some View {
        ZStack {
            if showGround {
                Rectangle().fill(Color(hex: "0e0b08"))
            }
            // Halo
            BubbleShape()
                .fill(Color(hex: "e89878").opacity(0.45))
                .frame(width: size * 0.72, height: size * 0.72)
                .blur(radius: size * 0.10)
            // Bubble fill
            BubbleShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "e89878"), Color(hex: "c96442")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: size * 0.72, height: size * 0.72)
                .overlay(
                    CaptionLines()
                        .frame(width: size * 0.72, height: size * 0.72)
                )
        }
        .frame(width: size, height: size)
        .modifier(SquircleClip(cornerRadius: cornerRadius))
        .accessibilityLabel("Earshot")
    }
}

private struct SquircleClip: ViewModifier {
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        if let r = cornerRadius {
            content.clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        } else {
            content
        }
    }
}

/// Speech-bubble outline, normalized to a 100×100 design grid that fills its frame.
/// Path matches the source SVG: `M14 22 Q14 14 22 14 H78 Q86 14 86 22 V60 Q86 68 78 68 H44 L28 82 V68 H22 Q14 68 14 60 Z`
/// after translation so x=14 → 0 and the tail (y=82) → 1.
private struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Source path lives in x ∈ [14, 86], y ∈ [14, 82]. Normalize to [0,1] then scale to rect.
        let originX: CGFloat = 14
        let originY: CGFloat = 14
        let w: CGFloat = 72   // 86 - 14
        let h: CGFloat = 68   // 82 - 14
        func sx(_ x: CGFloat) -> CGFloat { rect.minX + (x - originX) / w * rect.width }
        func sy(_ y: CGFloat) -> CGFloat { rect.minY + (y - originY) / h * rect.height }
        func cp(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: sx(x), y: sy(y)) }

        var p = Path()
        p.move(to: cp(14, 22))
        p.addQuadCurve(to: cp(22, 14), control: cp(14, 14))
        p.addLine(to: cp(78, 14))
        p.addQuadCurve(to: cp(86, 22), control: cp(86, 14))
        p.addLine(to: cp(86, 60))
        p.addQuadCurve(to: cp(78, 68), control: cp(86, 68))
        p.addLine(to: cp(44, 68))
        p.addLine(to: cp(28, 82))
        p.addLine(to: cp(28, 68))
        p.addLine(to: cp(22, 68))
        p.addQuadCurve(to: cp(14, 60), control: cp(14, 68))
        p.closeSubpath()
        return p
    }
}

/// Three knock-out caption lines inside the bubble. Same grid as `BubbleShape`.
private struct CaptionLines: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width / 72  // 72 design units = full width of bubble grid
            let h = geo.size.height / 68
            let ground = Color(hex: "1a1612")
            ZStack {
                line(x: 26, y: 30, len: 48, w: w, h: h, fill: ground)
                line(x: 26, y: 42, len: 36, w: w, h: h, fill: ground)
                line(x: 26, y: 54, len: 22, w: w, h: h, fill: ground)
            }
        }
    }

    private func line(x: CGFloat, y: CGFloat, len: CGFloat, w: CGFloat, h: CGFloat, fill: Color) -> some View {
        Capsule()
            .fill(fill)
            .frame(width: len * w, height: 6 * h)
            .position(x: (x - 14 + len / 2) * w, y: (y - 14 + 3) * h)
    }
}
