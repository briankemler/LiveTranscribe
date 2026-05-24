import SwiftUI

/// Centered pill shown when no speech has been heard for ≥ 5 s.
/// Spec §"Silence" + §"D1" + §"Interaction rules" item 7–8.
///
/// - `theme.surface` bg, capsule.
/// - Italic label: `"\(N) seconds of silence"`.
/// - Breathing dot 6×6, `theme.inkMute`, opacity 0.4 → 1 → 0.4, 2 s ease-in-out.
///   Off when `accessibilityReduceMotion` is on (dot stays at 0.7 — still visible but still).
struct CaptionsSilencePill: View {
    /// Whole seconds since the last finalized line. Parent computes from
    /// `LiveSession.silenceSeconds` on the 1-Hz timer tick.
    let silenceSeconds: Int

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(theme.inkMute)
                .frame(width: 6, height: 6)
                .opacity(reduceMotion ? 0.7 : (breathing ? 1.0 : 0.4))
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: breathing
                )

            Text("\(silenceSeconds) seconds of silence")
                .font(.scaled(size: 12, design: .serif, relativeTo: .caption1).italic())
                .foregroundStyle(theme.inkMute)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(theme.surface))
        .onAppear { breathing = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(silenceSeconds) seconds of silence, listening")
        // Hint VoiceOver that this value changes — pill text re-reads on tick if focus is here.
        .accessibilityAddTraits(.updatesFrequently)
    }
}
