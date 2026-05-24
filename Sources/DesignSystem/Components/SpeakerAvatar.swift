import SwiftUI

/// Circular speaker avatar — initial-only, colored per speaker.
struct SpeakerAvatar: View {
    let speaker: Speaker
    var size: CGFloat = 32

    @Environment(\.theme) private var theme
    @Environment(\.tweaks) private var tweaks

    var body: some View {
        let bg = tweaks.showSpeakerColors ? speaker.color(in: theme) : theme.inkSoft
        Text(speaker.initial)
            .font(.system(size: size * 0.42, weight: .heavy))
            .tracking(-0.3)
            .foregroundStyle(theme.bg)
            .frame(width: size, height: size)
            .background(Circle().fill(bg))
    }
}

/// Speaker name + avatar + waveform — used in 1:1 live header.
struct SpeakerNamePlate: View {
    let speaker: Speaker
    let displayName: String
    var speaking: Bool = true

    @Environment(\.theme) private var theme
    @Environment(\.tweaks) private var tweaks

    var body: some View {
        HStack(spacing: 12) {
            SpeakerAvatar(speaker: speaker, size: 44)
                .id(speaker.id)
                .transition(.opacity.combined(with: .move(edge: .leading)))
            VStack(alignment: .leading, spacing: 1) {
                Text(displayName)
                    .font(.scaled(size: 20, weight: .bold, relativeTo: .title3))
                    .tracking(-0.3)
                    .foregroundStyle(theme.ink)
                if speaking {
                    Text("SPEAKING NOW")
                        .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                        .tracking(0.5)
                        .foregroundStyle(theme.accent)
                }
            }
            Spacer(minLength: 0)
            if speaking {
                Waveform(color: tweaks.showSpeakerColors ? speaker.color(in: theme) : theme.inkSoft, count: 8, height: 20)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
    }
}
