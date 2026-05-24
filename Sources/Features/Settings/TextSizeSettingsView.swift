import SwiftUI

/// Pushed from Settings → Captions → Text size. Same pattern as LanguageSettingsView.
struct TextSizeSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var bindable = state

        VStack(spacing: 0) {
            TopBar(
                title: "Text size",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("How big captions read.")
                        .font(.scaled(size: 28, weight: .medium, design: .serif, relativeTo: .title1))
                        .tracking(-0.6)
                        .foregroundStyle(theme.ink)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        ForEach(Tweaks.TextSize.allCases.indices, id: \.self) { idx in
                            if idx > 0 {
                                Rectangle().fill(theme.line).frame(height: 1)
                            }
                            row(Tweaks.TextSize.allCases[idx], selection: $bindable.tweaks.textSize)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
                    )

                    preview
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func row(_ size: Tweaks.TextSize, selection: Binding<Tweaks.TextSize>) -> some View {
        let isSelected = selection.wrappedValue == size
        return Button {
            selection.wrappedValue = size
        } label: {
            HStack {
                Text(size.label)
                    .font(.system(size: 15 * size.scale, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(theme.ink)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.scaled(size: 13, weight: .heavy, relativeTo: .footnote))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var preview: some View {
        let size: CGFloat = 22 * state.tweaks.textSize.scale
        return VStack(alignment: .leading, spacing: 8) {
            Text("PREVIEW")
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .tracking(1.5)
                .foregroundStyle(theme.inkMute)
                .padding(.horizontal, 8)

            Text("A goose chased me around the lake.")
                .font(.system(size: size, weight: .medium, design: .serif))
                .tracking(-0.3)
                .foregroundStyle(theme.ink)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
                )
        }
    }
}
