import SwiftUI

/// Pushed from Settings → Captions → Speaker labels.
/// Controls how the Live screen labels who's talking.
struct DiarizationSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var bindable = state

        VStack(spacing: 0) {
            TopBar(
                title: "Speaker labels",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Who's talking.")
                        .font(.scaled(size: 28, weight: .medium, design: .serif, relativeTo: .title1))
                        .tracking(-0.6)
                        .foregroundStyle(theme.ink)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        ForEach(Tweaks.Diarization.allCases.indices, id: \.self) { idx in
                            if idx > 0 {
                                Rectangle().fill(theme.line).frame(height: 1)
                            }
                            row(Tweaks.Diarization.allCases[idx], selection: $bindable.tweaks.diarization)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
                    )

                    aboutCard
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

    private func row(_ mode: Tweaks.Diarization, selection: Binding<Tweaks.Diarization>) -> some View {
        let isSelected = selection.wrappedValue == mode
        return Button {
            selection.wrappedValue = mode
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.label)
                        .font(.scaled(size: 15, weight: isSelected ? .semibold : .regular, relativeTo: .subheadline))
                        .foregroundStyle(theme.ink)
                    Text(mode.blurb)
                        .font(.scaled(size: 11, relativeTo: .caption2))
                        .foregroundStyle(theme.inkMute)
                }
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

    private var aboutCard: some View {
        Text("Earshot uses a pause-based heuristic in group mode: when there's a long enough silence between sentences, the next line gets a new \"Speaker N\" label. This isn't real voice fingerprinting (that's a bigger model that's not in v1) — it's a good-enough proxy for casual conversation. 1:1 mode doesn't need labels.")
            .font(.scaled(size: 13, relativeTo: .footnote))
            .foregroundStyle(theme.inkSoft)
            .lineSpacing(3)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surfaceLo)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
            )
    }
}
