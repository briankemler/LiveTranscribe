import SwiftUI

/// Bottom sheet pushed from the cog button. Spec §"Quick settings bottom sheet".
///
/// Holds the in-conversation knobs the user might reach for mid-session: text size,
/// ambient sounds toggle, vibrate-on-alerts toggle, and a deep-link out to full settings.
/// Spec §"Interaction rules" item 6: tapping outside / grabber / close button dismisses.
struct CaptionsQuickSettingsSheet: View {
    /// Two-way binding on the full Tweaks struct so changes persist via the AppRoot onChange.
    @Binding var tweaks: Tweaks
    /// Pushes `.settings` on the nav stack. Called for the "All settings →" link.
    let openAllSettings: () -> Void
    /// Focus/Feed only applies in 1:1 mode — group always uses the cozy bubble layout, so the
    /// parent hides this row there to avoid a no-op control.
    var showLayoutRow: Bool = true
    /// The speaker-count control only makes sense in group mode (it tunes diarization). The
    /// parent shows it only there.
    var showSpeakerCountRow: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // Spec: grabber, 38×4, lineHi.
            Capsule()
                .fill(theme.lineHi)
                .frame(width: 38, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Title row: "Adjust" + close button.
            HStack {
                Text("Adjust")
                    .font(.scaled(size: 19, weight: .semibold, design: .serif, relativeTo: .title3))
                    .tracking(-0.4)
                    .foregroundStyle(theme.ink)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.scaled(size: 14, weight: .semibold, relativeTo: .footnote))
                        .foregroundStyle(theme.inkSoft)
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)

            // Settings rows, each separated by a hairline matching `theme.line`.
            if showLayoutRow {
                layoutRow
                Divider().background(theme.line)
            }
            if showSpeakerCountRow {
                speakerCountRow
                Divider().background(theme.line)
            }
            textSizeRow
            Divider().background(theme.line)
            ambientSoundsRow
            Divider().background(theme.line)
            vibrateOnAlertsRow
            Divider().background(theme.line)
            allSettingsRow

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(theme.surface)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Rows

    /// Layout segmented control — Focus (teleprompter) vs Feed (chat-style scroll).
    private var layoutRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LAYOUT")
                .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(theme.inkMute)

            HStack(spacing: 6) {
                ForEach(Tweaks.CaptionLayout.allCases) { layout in
                    let isSelected = tweaks.captionLayout == layout
                    Button {
                        tweaks.captionLayout = layout
                    } label: {
                        Text(layout.label)
                            .font(.scaled(size: 13, weight: .semibold, relativeTo: .subheadline))
                            .foregroundStyle(isSelected ? theme.onAccent : theme.inkSoft)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(isSelected ? theme.accent : .clear))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(layout.label) layout")
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(3)
            .background(Capsule().fill(theme.bg))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
    }

    /// Speakers segmented control — Auto / 1 / 2 / 3 / 4. A fixed count is handed to pyannote as
    /// a hard constraint, which is far more reliable than auto-estimating how many voices are
    /// present. Group mode only.
    private var speakerCountRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SPEAKERS")
                .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(theme.inkMute)

            HStack(spacing: 6) {
                ForEach(Tweaks.GroupSpeakerCount.allCases) { option in
                    let isSelected = tweaks.groupSpeakerCount == option
                    Button {
                        tweaks.groupSpeakerCount = option
                    } label: {
                        Text(option.label)
                            .font(.scaled(size: 13, weight: .semibold, relativeTo: .subheadline))
                            .foregroundStyle(isSelected ? theme.onAccent : theme.inkSoft)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(isSelected ? theme.accent : .clear))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option == .auto ? "Auto speaker count" : "\(option.label) speakers")
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(3)
            .background(Capsule().fill(theme.bg))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
    }

    /// Spec §"Text size" — segmented A/A/A/A. Bound to existing `Tweaks.TextSize` enum
    /// (.small / .regular / .large / .huge). Selected pill = `theme.accent` bg.
    private var textSizeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TEXT SIZE")
                .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(theme.inkMute)

            HStack(spacing: 6) {
                ForEach(Tweaks.TextSize.allCases) { size in
                    sizeButton(size)
                }
            }
            .padding(3)
            .background(Capsule().fill(theme.bg))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
    }

    /// One of the four A buttons. Glyph size scales with the option so the row visually
    /// communicates Small/Regular/Large/Huge even at AX5 (the relative Font.TextStyle
    /// keeps things sensible).
    private func sizeButton(_ size: Tweaks.TextSize) -> some View {
        let isSelected = tweaks.textSize == size
        // Map the 4 levels to ascending visible sizes for the A glyph.
        let glyphSize: CGFloat = {
            switch size {
            case .small: 11
            case .regular: 13
            case .large: 16
            case .huge: 20
            }
        }()
        let relativeStyle: UIFont.TextStyle = {
            switch size {
            case .small: .caption2
            case .regular: .footnote
            case .large: .body
            case .huge: .title3
            }
        }()
        return Button {
            tweaks.textSize = size
        } label: {
            Text("A")
                .font(.scaled(size: glyphSize, weight: .semibold, relativeTo: relativeStyle))
                .foregroundStyle(isSelected ? theme.onAccent : theme.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? theme.accent : .clear))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(size.label) text size")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var ambientSoundsRow: some View {
        toggleRow(
            title: "Show ambient sounds",
            sub: "Tags like \"jazz\" in the corner",
            isOn: $tweaks.showAmbientSounds
        )
    }

    private var vibrateOnAlertsRow: some View {
        toggleRow(
            title: "Vibrate on alerts",
            sub: "Smoke alarm, doorbell, baby crying",
            isOn: $tweaks.vibrateOnAlerts
        )
    }

    private func toggleRow(title: String, sub: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.scaled(size: 14, weight: .medium, relativeTo: .subheadline))
                    .foregroundStyle(theme.ink)
                Text(sub)
                    .font(.scaled(size: 11, relativeTo: .caption2))
                    .foregroundStyle(theme.inkMute)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: theme.accent))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
    }

    /// "All settings →" link. Dismisses the sheet first so the deep settings screen pushes
    /// cleanly on top of the captions screen rather than fighting the sheet presentation.
    private var allSettingsRow: some View {
        HStack {
            Text("Sound recognition, diarization, more…")
                .font(.scaled(size: 13, relativeTo: .footnote))
                .foregroundStyle(theme.inkSoft)
            Spacer(minLength: 0)
            Button {
                dismiss()
                // Give the sheet a beat to dismiss before pushing the next screen, so the
                // navigation animation doesn't fight the sheet collapse.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    openAllSettings()
                }
            } label: {
                Text("All settings →")
                    .font(.scaled(size: 12, weight: .heavy, relativeTo: .caption2))
                    .tracking(0.5)
                    .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open all settings")
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
}
