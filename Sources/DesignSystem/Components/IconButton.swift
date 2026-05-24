import SwiftUI

/// 40×40 round-tap-target icon button. Mirrors `IconBtn` from the source.
///
/// **Accessibility:** always pass `accessibilityLabel` — a meaningful verb like "Back",
/// "Close", "Settings". VoiceOver fallback to the SF Symbol name ("chevron.left") is
/// confusing for users. The label parameter is optional only because some call sites use
/// the button purely decoratively; those should set `accessibilityHidden`.
struct IconButton: View {
    let systemName: String
    let action: () -> Void
    var color: Color? = nil
    var size: CGFloat = 20
    var accessibilityLabel: String? = nil

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.scaled(size: size, weight: .medium, relativeTo: .title3))
                .foregroundStyle(color ?? theme.ink)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? systemName.replacingOccurrences(of: ".", with: " "))
    }
}

/// "ON-DEVICE" pill that recurs throughout the app to reinforce privacy.
struct PrivacyPill: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "cpu")
                .font(.scaled(size: 9, weight: .heavy, relativeTo: .caption2))
            Text("ON-DEVICE")
                .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                .tracking(0.6)
        }
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(theme.accentSoft)
        )
    }
}

/// Top bar with optional left, title, subtitle, right.
struct TopBar<Left: View, Right: View>: View {
    let title: String?
    let subtitle: String?
    @ViewBuilder var left: () -> Left
    @ViewBuilder var right: () -> Right

    @Environment(\.theme) private var theme

    init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder left: @escaping () -> Left = { EmptyView() },
        @ViewBuilder right: @escaping () -> Right = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.left = left
        self.right = right
    }

    var body: some View {
        HStack(spacing: 8) {
            left()
            VStack(alignment: .leading, spacing: 1) {
                if let title {
                    Text(title)
                        .font(.scaled(size: 14, weight: .semibold, relativeTo: .subheadline))
                        .foregroundStyle(theme.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.scaled(size: 11, relativeTo: .caption2))
                        .foregroundStyle(theme.inkMute)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            right()
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
    }
}
