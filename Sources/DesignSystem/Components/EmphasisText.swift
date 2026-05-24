import SwiftUI

/// Renders a transcript line with the optional `emphasis` substring shown serif-italic in the accent.
/// Uses `Text` concatenation with `+` so it stays one paragraph that wraps naturally.
struct EmphasisText: View {
    let line: TranscriptLine
    let baseSize: CGFloat
    var weight: Font.Weight = .medium
    var lineSpacing: CGFloat = 0
    var letterSpacing: CGFloat = 0

    @Environment(\.theme) private var theme

    var body: some View {
        baseText
            .lineSpacing(lineSpacing)
            .tracking(letterSpacing)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(line.text)
    }

    private var baseText: Text {
        let text = line.text
        guard let emphasis = line.emphasis,
              let range = text.range(of: emphasis, options: .caseInsensitive)
        else {
            return Text(text)
                .font(.system(size: baseSize, weight: weight, design: .serif))
                .foregroundStyle(theme.ink)
        }
        let pre = String(text[..<range.lowerBound])
        let mid = String(text[range])
        let post = String(text[range.upperBound...])
        return Text(pre)
            .font(.system(size: baseSize, weight: weight, design: .serif))
            .foregroundStyle(theme.ink)
        + Text(mid)
            .font(.system(size: baseSize, weight: weight, design: .serif).italic())
            .foregroundStyle(theme.accent)
        + Text(post)
            .font(.system(size: baseSize, weight: weight, design: .serif))
            .foregroundStyle(theme.ink)
    }
}

/// Two-line title with the second line in serif-italic accent. Used on Onboarding, Home, Summary, etc.
struct AccentItalicTitle: View {
    let lead: String
    let accentLine: String
    var size: CGFloat = 56
    var lineHeight: CGFloat = 0.98
    var tracking: CGFloat = -2

    @Environment(\.theme) private var theme

    var body: some View {
        let leadText = Text(lead + (lead.hasSuffix("\n") ? "" : "\n"))
            .font(.system(size: size, weight: .medium, design: .serif))
            .foregroundStyle(theme.ink)
        let accentText = Text(accentLine)
            .font(.system(size: size, weight: .medium, design: .serif).italic())
            .foregroundStyle(theme.accent)
        (leadText + accentText)
            .lineSpacing(0)
            .tracking(tracking)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(lead.replacingOccurrences(of: "\n", with: " ") + accentLine)
            // Clamp display serif growth so AX5 doesn't push the headline off-screen on iPhone
            // SE. Chrome below the headline keeps scaling all the way up — only display serif
            // is clamped here.
            .displaySerifDynamicTypeClamp()
    }
}
