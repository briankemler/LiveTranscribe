import SwiftUI

/// All-caps small heading in the accent color. Used as a section kicker throughout.
struct Kicker: View {
    let text: String
    var color: Color? = nil
    var tracking: CGFloat = 2

    @Environment(\.theme) private var theme

    var body: some View {
        Text(text.uppercased())
            .font(AppFont.kicker)
            .tracking(tracking)
            .foregroundStyle(color ?? theme.accent)
    }
}

/// Pagination dot row. Shown on onboarding + the model-download teach card.
struct DotProgress: View {
    let total: Int
    let current: Int

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? theme.accent : theme.lineHi)
                    .frame(width: i == current ? 24 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: current)
            }
        }
        .accessibilityHidden(true)
    }
}
