import SwiftUI

/// Vertical bar that blinks 1Hz. Mirrors the `.sp-caret` element in the source.
struct BlinkingCaret: View {
    var height: CGFloat = 36
    var width: CGFloat = 4

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var on = true

    var body: some View {
        Rectangle()
            .fill(theme.accent)
            .frame(width: width, height: height)
            .opacity(on ? 1 : 0.2)
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    on = false
                }
            }
    }
}
