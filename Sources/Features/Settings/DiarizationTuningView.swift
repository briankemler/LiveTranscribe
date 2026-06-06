import SwiftUI

/// Developer-only live tuning for software speaker separation (diarization). Reached from the
/// hidden Developer section (tap the Version row 7×). Bindings write `AppState.diarizationTuning`,
/// which the running captions session observes — so changes take effect on the **next pass**,
/// letting you dial values in on-device with real audio instead of round-tripping through builds.
///
/// The primary, user-facing lever is the "How many people?" picker in the captions controls; these
/// are the secondary knobs that don't belong in front of users.
struct DiarizationTuningView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var bindable = state

        VStack(spacing: 0) {
            TopBar(
                title: "Diarization tuning",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Speaker separation.")
                        .font(.scaled(size: 28, weight: .medium, design: .serif, relativeTo: .title1))
                        .tracking(-0.6)
                        .foregroundStyle(theme.ink)
                        .padding(.horizontal, 8)

                    Text("Developer knobs, applied live to a running session on the next pass. The user-facing control is “How many people?” in the captions sheet — these are secondary.")
                        .font(.scaled(size: 13, relativeTo: .footnote))
                        .foregroundStyle(theme.inkSoft)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        sliderRow("Cluster threshold",
                                  value: $bindable.diarizationTuning.clusterThreshold,
                                  range: DiarizationTuning.clusterThresholdRange, step: 0.01, decimals: 2,
                                  hint: "Higher merges more (fewer speakers); lower splits more.")
                        divider
                        sliderRow("Window length",
                                  value: $bindable.diarizationTuning.windowSeconds,
                                  range: DiarizationTuning.windowRange, step: 1, decimals: 0, unit: "s",
                                  hint: "Span re-clustered each pass. Longer = better re-ID of returning voices, more compute.")
                        divider
                        sliderRow("Pass cadence",
                                  value: $bindable.diarizationTuning.strideSeconds,
                                  range: DiarizationTuning.strideRange, step: 1, decimals: 0, unit: "s",
                                  hint: "How often a pass runs. Smaller = more responsive but hotter.")
                        divider
                        sliderRow("New-speaker gate",
                                  value: $bindable.diarizationTuning.minNewSpeakerSeconds,
                                  range: DiarizationTuning.minNewSpeakerRange, step: 0.1, decimals: 1, unit: "s",
                                  hint: "Speech a new voice must accumulate before earning a pill.")
                    }
                    .background(card)

                    Button { state.diarizationTuning = .defaults } label: {
                        Text("Reset to defaults")
                            .font(.scaled(size: 14, weight: .semibold, relativeTo: .subheadline))
                            .foregroundStyle(theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(card)
                    }
                    .buttonStyle(.plain)
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

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                           step: Double, decimals: Int, unit: String = "", hint: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.scaled(size: 14, weight: .medium, relativeTo: .subheadline))
                    .foregroundStyle(theme.ink)
                Spacer()
                Text(String(format: "%.\(decimals)f", value.wrappedValue) + unit)
                    .font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
                    .monospacedDigit()
                    .foregroundStyle(theme.accent)
            }
            Slider(value: value, in: range, step: step).tint(theme.accent)
            Text(hint)
                .font(.scaled(size: 11, relativeTo: .caption2))
                .foregroundStyle(theme.inkMute)
                .lineSpacing(2)
        }
        .padding(16)
    }

    private var divider: some View { Rectangle().fill(theme.line).frame(height: 1) }

    private var card: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
    }
}
