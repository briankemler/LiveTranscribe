import SwiftUI

struct PrimaryButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder var label: () -> Label
    var fullWidth: Bool = true
    var fillOverride: Color? = nil

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) { label() }
                .font(.scaled(size: 17, weight: .bold, relativeTo: .body))
                .foregroundStyle(theme.onAccent)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .frame(height: 56)
                .padding(.horizontal, fullWidth ? 0 : 28)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(fillOverride ?? theme.accent)
                )
        }
        .buttonStyle(.plain)
    }
}

struct GhostButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder var label: () -> Label
    var fullWidth: Bool = true

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) { label() }
                .font(.scaled(size: 14, weight: .semibold, relativeTo: .subheadline))
                .foregroundStyle(theme.ink)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .frame(height: 48)
                .padding(.horizontal, fullWidth ? 0 : 22)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(theme.surfaceLo)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(theme.lineHi, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
