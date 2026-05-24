import SwiftUI

/// Right-margin ambient-sound tag. Spec §"Right-margin sound tag (B2)".
///
/// - 11 pt uppercase, letter-spacing 1, `theme.inkMute`, weight 700.
/// - Format: `[icon] LABEL` (`♫ JAZZ`, `💬 LAUGHTER`).
/// - Crossfades on label change (300 ms per spec §"Interaction rules" item 9).
/// - **Urgent sounds bypass this tag** — smoke alarm / doorbell / baby crying still use
///   the full-bleed `AlertView` per spec §10. Only non-urgent ambient categories land here.
/// - In build 12 the real ambient classifier isn't wired yet; the parent only renders this
///   tag when `tweaks.showAmbientSounds` is on, and passes a placeholder until the
///   non-urgent SoundAnalysis path lands.
struct SoundMarginTag: View {
    let icon: String   // SF Symbol name
    let label: String  // Will be uppercased

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
            Text(label.uppercased())
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .tracking(1)
        }
        .foregroundStyle(theme.inkMute)
        .transition(.opacity)  // 300 ms crossfade applied by the parent's animation modifier
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ambient sound: \(label)")
    }
}
