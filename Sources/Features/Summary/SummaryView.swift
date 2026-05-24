import SwiftUI
import SwiftData

/// Pushed from Home / History / a freshly-finished Live session. Renders a real
/// `ConversationRecord` looked up from SwiftData. The optional `conversationID` lets the
/// showcase deck push `Route.summary(nil)` — we fall back to the most recent non-empty
/// conversation in that case so the deck has something to render.
///
/// Build 15:
///   - Top bar gets share, show-full-text toggle, and star (conversation-level toggle).
///   - Removed the rewind-10s icon — playback isn't a feature.
///   - Per-line star UI is gone since starring is now conversation-level (build 14).
///
/// Build 21:
///   - Transcript body is now a continuous-prose **document** (paragraphs grouped at
///     natural pauses, no speaker labels) instead of per-utterance cards. The card view +
///     format-toggle button are gone. Document structure comes from
///     `ConversationRecord.documentParagraphs`, shared with `plainTextExport`.
struct SummaryView: View {
    let conversationID: UUID?

    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    @State private var conversation: ConversationRecord?
    /// Drives the system share sheet. Prerendered text so we don't re-touch SwiftData
    /// while the activity controller is up.
    @State private var shareTarget: HistoryView.ShareTarget?

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                left: { IconButton(systemName: "xmark", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Close") },
                right: {
                    if let conv = conversation, !conv.lines.isEmpty {
                        topBarActions(for: conv)
                    }
                }
            )

            if let conv = conversation {
                content(for: conv)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { loadConversation() }
        .sheet(item: $shareTarget) { target in
            ShareSheet(items: [target.text], subject: target.subject)
        }
    }

    private func loadConversation() {
        if let id = conversationID {
            conversation = ConversationStore.fetchConversation(id: id, in: modelContext)
        } else {
            conversation = ConversationStore.mostRecentNonEmpty(in: modelContext)
        }
    }

    // MARK: - Top bar actions

    /// Two icon buttons on the right side of the top bar: share + star.
    private func topBarActions(for conv: ConversationRecord) -> some View {
        HStack(spacing: 4) {
            // Share — opens the system share sheet with the plain-text transcript.
            Button {
                shareTarget = HistoryView.ShareTarget(
                    id: conv.id,
                    text: conv.plainTextExport,
                    subject: "Earshot — \(HomeView.titleFor(conv))"
                )
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.scaled(size: 17, weight: .medium, relativeTo: .body))
                    .foregroundStyle(theme.inkSoft)
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share transcript")

            // Star — conversation-level bookmark. Hollow when off, filled when starred.
            Button {
                conv.isStarred.toggle()
                try? modelContext.save()
            } label: {
                Image(systemName: conv.isStarred ? "star.fill" : "star")
                    .font(.scaled(size: 17, weight: .medium, relativeTo: .body))
                    .foregroundStyle(conv.isStarred ? theme.accent : theme.inkSoft)
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(conv.isStarred ? "Unstar transcript" : "Star transcript")
        }
    }

    // MARK: - Main content

    @ViewBuilder
    private func content(for conv: ConversationRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Kicker(text: "THAT'S A WRAP")
            Text(HomeView.titleFor(conv))
                .font(.scaled(size: 40, weight: .medium, design: .serif, relativeTo: .largeTitle))
                .tracking(-1.4)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(rangeText(for: conv))
                .font(.scaled(size: 13, relativeTo: .footnote))
                .foregroundStyle(theme.inkSoft)
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .padding(.bottom, 16)

        HStack(spacing: 8) {
            statCard(value: "\(max(1, conv.speakerCount))", label: conv.speakerCount == 1 ? "voice" : "voices")
            statCard(value: "\(conv.lines.count)", label: conv.lines.count == 1 ? "line" : "lines")
            statCard(value: "\(conv.detections.count)", label: conv.detections.count == 1 ? "alert" : "alerts")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)

        documentBody(for: conv)

        HStack(spacing: 10) {
            PrimaryButton(action: { state.path.removeLast() }) {
                Image(systemName: "checkmark")
                    .font(.scaled(size: 16, weight: .heavy, relativeTo: .body))
                Text("Done")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(theme.line), alignment: .top)
        .padding(.bottom, 4)
    }

    // MARK: - Document body

    /// Continuous-prose document: paragraphs from `conv.documentParagraphs` rendered as
    /// flowing serif text, with the detected-alerts chips below. Text selection is enabled
    /// so a user can long-press to copy any passage. Empty-transcript fallback covers the
    /// (rare) case of a saved conversation with no finalized lines.
    private func documentBody(for conv: ConversationRecord) -> some View {
        let paragraphs = conv.documentParagraphs
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("TRANSCRIPT")
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(1.5)
                    .foregroundStyle(theme.inkMute)
                    .padding(.bottom, 2)

                if paragraphs.isEmpty {
                    Text("No words were transcribed in this session.")
                        .font(.scaled(size: 14, relativeTo: .subheadline))
                        .foregroundStyle(theme.inkMute)
                } else {
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(.scaled(size: 17, design: .serif, relativeTo: .body))
                            .foregroundStyle(theme.ink)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }

                if !conv.detections.isEmpty {
                    Spacer().frame(height: 6)
                    Text("ALERTS DETECTED")
                        .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                        .tracking(1.5)
                        .foregroundStyle(theme.inkMute)
                        .padding(.bottom, 2)
                    FlowLayout(spacing: 6) {
                        ForEach(conv.detections.sorted(by: { $0.detectedAt < $1.detectedAt }), id: \.id) { det in
                            alertChip(det)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer()
            Image(systemName: "tray")
                .font(.scaled(size: 32, weight: .semibold, relativeTo: .largeTitle))
                .foregroundStyle(theme.inkMute)
            Text("No conversation to show.")
                .font(.scaled(size: 16, weight: .semibold, design: .serif, relativeTo: .body))
                .foregroundStyle(theme.inkSoft)
            Text("Start a new live session to capture one.")
                .font(.scaled(size: 12, relativeTo: .caption1))
                .foregroundStyle(theme.inkMute)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Alert chip

    private func alertChip(_ det: SoundDetectionRecord) -> some View {
        HStack(spacing: 5) {
            Image(systemName: det.icon).font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
            Text(det.label).font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
            Text(timeAt(det.detectedAt.timeIntervalSince(conversation?.startedAt ?? det.detectedAt)))
                .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                .opacity(0.7)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(theme.alert))
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.scaled(size: 28, weight: .semibold, design: .serif, relativeTo: .title1))
                .foregroundStyle(theme.ink)
            Text(label.uppercased())
                .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(theme.inkMute)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }

    /// `mm:ss` formatter for in-conversation audio timestamps.
    private func timeAt(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// Either "Today · 9:33–10:24 AM · 51m" or "May 8 · 9:33–9:55 AM · 22m". End time uses
    /// `endedAt` if the session was closed cleanly, else now.
    private func rangeText(for conv: ConversationRecord) -> String {
        let start = conv.startedAt
        let end = conv.endedAt ?? Date()
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "h:mm"
        let suffixFmt = DateFormatter()
        suffixFmt.dateFormat = "a"
        let startStr = timeFmt.string(from: start)
        let endStr = timeFmt.string(from: end)
        let suffix = suffixFmt.string(from: end)
        let mins = Int(conv.duration / 60)
        let secs = Int(conv.duration) % 60
        let durStr = mins > 0 ? "\(mins)m" : "\(secs)s"
        return "\(startStr)–\(endStr) \(suffix) · \(durStr)"
    }
}
