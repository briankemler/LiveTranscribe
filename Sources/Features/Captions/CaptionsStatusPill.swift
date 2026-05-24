import SwiftUI

/// Always-visible status pill in the top-left of `CaptionsView`.
/// Implements spec §"Status pill (always visible)" from `Design/CAPTIONS_HANDOFF.md`.
///
/// - 4-bar animated waveform in `theme.accent` (peach) reusing `Waveform`.
/// - Tabular-num clock "Listening · HH:MM:SS" updates from the parent's 1-Hz timer.
/// - `theme.surface` background, 6×12 padding, capsule.
struct CaptionsStatusPill: View {
    /// Wall-clock duration of the live session in seconds. Parent computes and passes in.
    let elapsedSeconds: TimeInterval

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            // Spec: 4 bars, 2.5 pt wide, peach. Existing Waveform supports parameters.
            Waveform(color: theme.accent, count: 4, height: 10, barWidth: 2.5)

            Text("Listening · \(Self.formatted(elapsedSeconds))")
                .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption1))
                .tracking(0.3)
                .monospacedDigit()
                .foregroundStyle(theme.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Listening, \(Self.spokenDuration(elapsedSeconds))")
        .accessibilityAddTraits(.updatesFrequently)
    }

    /// "H:MM:SS" when ≥ 1 hour, else "M:SS". Mirrors the spec's `0:08:42` example which is
    /// always H:MM:SS — but for short sessions M:SS reads better. We pick based on length.
    private static func formatted(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }

    /// VoiceOver-friendly readout — "8 minutes, 42 seconds" rather than the digit form.
    private static func spokenDuration(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        let m = s / 60
        let sec = s % 60
        if m == 0 { return "\(sec) seconds" }
        if sec == 0 { return "\(m) minute\(m == 1 ? "" : "s")" }
        return "\(m) minute\(m == 1 ? "" : "s"), \(sec) seconds"
    }
}
