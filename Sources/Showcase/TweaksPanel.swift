import SwiftUI

struct TweaksPanel: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var state = state

        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                section("Palette") {
                    HStack(spacing: 8) {
                        ForEach(PaletteID.allCases) { id in
                            paletteSwatch(id, isSelected: state.tweaks.palette == id) {
                                state.tweaks.palette = id
                            }
                        }
                    }
                }

                section("Text size") {
                    segmented(
                        options: Tweaks.TextSize.allCases,
                        selected: state.tweaks.textSize,
                        labels: { $0.label }
                    ) { state.tweaks.textSize = $0 }
                }

                section("Diarization") {
                    VStack(alignment: .leading, spacing: 8) {
                        segmented(
                            options: Tweaks.Diarization.allCases,
                            selected: state.tweaks.diarization,
                            labels: { $0.label }
                        ) { state.tweaks.diarization = $0 }
                        Text(state.tweaks.diarization.blurb)
                            .font(.scaled(size: 12, relativeTo: .caption1))
                            .foregroundStyle(theme.inkMute)
                    }
                }

                toggleRow("Show speaker colors", isOn: $state.tweaks.showSpeakerColors)

                Divider().background(theme.line)

                Button {
                    state.showcaseOpen = true
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.stack.fill")
                        Text("Open showcase deck")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(theme.ink)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(theme.line, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.bgSoft)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Kicker(text: "TWEAKS")
            Text("Make it yours.")
                .font(.scaled(size: 30, weight: .medium, design: .serif, relativeTo: .title1))
                .tracking(-0.6)
                .foregroundStyle(theme.ink)
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .tracking(1.5)
                .foregroundStyle(theme.inkMute)
            content()
        }
    }

    private func paletteSwatch(_ id: PaletteID, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let theme = id.theme
        return Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.bg)
                    HStack(spacing: 6) {
                        Circle().fill(theme.accent).frame(width: 14, height: 14)
                        Circle().fill(theme.spkB).frame(width: 10, height: 10)
                        Circle().fill(theme.spkD).frame(width: 10, height: 10)
                    }
                    .padding(10)
                    Text(id.label.uppercased())
                        .font(.scaled(size: 9, weight: .heavy, relativeTo: .caption2))
                        .tracking(1)
                        .foregroundStyle(theme.inkSoft)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? theme.accent : theme.line, lineWidth: isSelected ? 2 : 1)
                )
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func segmented<T: Identifiable & Hashable>(
        options: [T],
        selected: T,
        labels: @escaping (T) -> String,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(options) { opt in
                let isSel = opt == selected
                Button { onSelect(opt) } label: {
                    Text(labels(opt))
                        .font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
                        .foregroundStyle(isSel ? theme.onAccent : theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            isSel ? AnyShapeStyle(theme.accent) : AnyShapeStyle(.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(theme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label).font(.scaled(size: 14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(theme.ink)
        }
        .toggleStyle(SwitchToggleStyle(tint: theme.accent))
    }
}
