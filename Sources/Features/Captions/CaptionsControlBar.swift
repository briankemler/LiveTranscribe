import SwiftUI

/// Floating control bar at the bottom of `CaptionsView`. Spec §"Floating bar (transient)".
///
/// Hidden state: `.offset(y: 90) + .opacity(0)`. Reveal: spring approximating the spec's
/// `cubic-bezier(0.2, 0.8, 0.2, 1)` over 250 ms. Tap on the bar itself is swallowed by an
/// empty `.onTapGesture {}` so the parent's tap-to-reveal doesn't see it (spec §"Interaction
/// rules" item 2).
///
/// Buttons (left → right per spec): **cog** (40×40) opens quick-settings sheet; **star**
/// (40×40) flags the most recent finalized line in SwiftData (`LiveSession.starMostRecentLine`);
/// **pause** (44×44, peach bg) calls `LiveSession.endAndSave()` and navigates to Summary.
struct CaptionsControlBar: View {
    /// Bound from parent; flips on tap-to-reveal and auto-hides after 3 s.
    let visible: Bool
    /// True while the star toast overlay is up — drives the star icon's filled state.
    let starHighlighted: Bool

    let onTapCog: () -> Void
    let onTapStar: () -> Void
    let onTapPause: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            barButton(systemName: "gearshape", size: 40, label: "Adjust captions", action: onTapCog)
            barButton(
                systemName: starHighlighted ? "star.fill" : "star",
                size: 40,
                label: "Save this moment",
                color: starHighlighted ? theme.accent : theme.inkSoft,
                action: onTapStar
            )

            Spacer(minLength: 0)

            // Pause is the only filled / accented button — emphasized per spec.
            Button(action: onTapPause) {
                Image(systemName: "pause.fill")
                    .font(.scaled(size: 18, weight: .heavy, relativeTo: .body))
                    .foregroundStyle(theme.onAccent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(theme.accent))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("End and save")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            // Closest SwiftUI equivalent to spec's rgba(42,35,29,0.92) + backdrop-filter:
            // blur(20px) — system material does the blur, tinted by the theme surface.
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.surface.opacity(0.92))
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(theme.lineHi, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 16, y: 12)
        .offset(y: visible ? 0 : 90)
        .opacity(visible ? 1 : 0)
        // Reduce-Motion: skip the slide + opacity transition entirely.
        .animation(
            reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.85),
            value: visible
        )
        // Spec §"Interaction rules" item 2: tapping the bar does NOT reset the 3 s auto-hide.
        // Empty tap handler stops the gesture from propagating to the parent's tap-to-reveal.
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture { /* swallow */ }
        .allowsHitTesting(visible)
    }

    @ViewBuilder
    private func barButton(
        systemName: String,
        size: CGFloat,
        label: String,
        color: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.scaled(size: 18, weight: .medium, relativeTo: .body))
                .foregroundStyle(color ?? theme.inkSoft)
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
