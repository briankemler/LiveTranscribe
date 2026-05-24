import SwiftUI

/// Three-tone sound chip (alert / social / ambient) — matches `SoundChip` in the source.
struct SoundChip: View {
    enum Tone { case alert, social, ambient }

    let systemIcon: String
    let label: String
    var time: String? = nil
    var tone: Tone = .ambient
    var strong: Bool = false

    @Environment(\.theme) private var theme

    var body: some View {
        let palette = colors(for: tone)
        HStack(spacing: 6) {
            Image(systemName: systemIcon)
                .font(.scaled(size: 12, weight: .bold, relativeTo: .caption1))
            Text(label)
                .font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
            if let time {
                Text(time)
                    .font(.scaled(size: 12, weight: .medium, relativeTo: .caption1))
                    .monospacedDigit()
                    .opacity(0.55)
            }
        }
        .foregroundStyle(palette.fg)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(palette.bg)
        )
        .overlay(
            Capsule().stroke(palette.border, lineWidth: tone == .alert ? 1 : 0)
        )
        .shadow(color: strong ? theme.alertSoft : .clear, radius: 0, y: 0)
    }

    private struct ChipPalette {
        let bg: Color; let fg: Color; let border: Color
    }

    private func colors(for tone: Tone) -> ChipPalette {
        switch tone {
        case .ambient: ChipPalette(bg: theme.ambientSoft, fg: theme.inkSoft, border: .clear)
        case .social:  ChipPalette(bg: theme.socialSoft,  fg: theme.social,  border: .clear)
        case .alert:   ChipPalette(bg: theme.alertSoft,   fg: theme.alert,   border: theme.alert)
        }
    }
}
