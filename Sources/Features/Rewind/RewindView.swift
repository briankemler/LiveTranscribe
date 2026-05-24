import SwiftUI
import SwiftData

/// Catch-up view for an in-progress or just-finished conversation. Shows the persisted
/// transcript with timestamps so the user can scroll back through what was said. Replaces
/// the design's faux audio-scrubber with a text scroller pinned to the most recent line —
/// real audio playback isn't recorded in v1 (no on-disk PCM ring buffer yet), and for an
/// accessibility-driven product, text rewind is arguably more useful than audio anyway.
struct RewindView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var conversation: ConversationRecord?

    private var orderedLines: [TranscriptLineRecord] {
        conversation?.lines.sorted(by: { $0.audioStart < $1.audioStart }) ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TopBar(
                title: "Rewind",
                left: { IconButton(systemName: "xmark", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Close") },
                right: {
                    if !orderedLines.isEmpty {
                        Button { state.path.removeLast() } label: {
                            Text("Catch up →")
                                .font(.scaled(size: 13, weight: .bold, relativeTo: .footnote))
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            )

            VStack(alignment: .leading, spacing: 6) {
                AccentItalicTitle(lead: "Scroll back to", accentLine: "catch up.", size: 30, tracking: -0.8)
                Text(subtitleText)
                    .font(.scaled(size: 13, relativeTo: .footnote))
                    .foregroundStyle(theme.inkSoft)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)

            if orderedLines.isEmpty {
                empty
            } else {
                transcript
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { loadConversation() }
    }

    private func loadConversation() {
        // Always pulls the most recent non-empty conversation. Good default for the in-flight
        // case (LiveView pushes .rewind while a session is running and currentLine is in the
        // record); also works for the "just finished" path on the Summary screen.
        conversation = ConversationStore.mostRecentNonEmpty(in: modelContext)
    }

    private var subtitleText: String {
        guard let conv = conversation else { return "No transcript to rewind through yet." }
        if conv.endedAt == nil { return "Live transcript keeps going underneath." }
        return "Saved conversation · \(HomeView.metaFor(conv))"
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nothing to rewind yet.")
                .font(.scaled(size: 16, weight: .semibold, design: .serif, relativeTo: .body))
                .foregroundStyle(theme.inkSoft)
            Text("Start a live session — lines you can scroll back through will collect here.")
                .font(.scaled(size: 12, relativeTo: .caption1))
                .foregroundStyle(theme.inkMute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(orderedLines, id: \.id) { line in
                        lineCard(line)
                            .id(line.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .onAppear {
                // Scroll-pin to the most recent line so the rewind UX matches a "scroll up to
                // go back in time" model. The user scrolls upward to read earlier captions.
                if let last = orderedLines.last {
                    DispatchQueue.main.async {
                        if reduceMotion {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        } else {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }
        }
    }

    private func lineCard(_ line: TranscriptLineRecord) -> some View {
        let color = line.speaker.color(in: theme)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(line.speakerDisplayName.uppercased())
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(0.4)
                    .foregroundStyle(color)
                Text(timestamp(line.audioStart))
                    .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                    .tracking(0.4)
                    .foregroundStyle(theme.inkMute)
                    .monospacedDigit()
                Spacer()
            }
            Text(line.text)
                .font(.scaled(size: 16, weight: .regular, design: .serif, relativeTo: .body))
                .tracking(-0.2)
                .foregroundStyle(theme.ink)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface)
        )
        .overlay(
            Rectangle().fill(color).frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)),
            alignment: .leading
        )
    }

    private func timestamp(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
