import Foundation

/// Plain-text export of a `ConversationRecord`. Used by the share sheet on `HistoryView` and
/// `SummaryView` so a user can save a transcript to Notes, Files, Google Drive, or send it
/// via iMessage / Mail.
///
/// Format (continuous-prose document — matches the on-screen SummaryView):
/// ```
/// Earshot — Today · 9:33 AM
/// 1:1 · 51m · 2 voices
///
/// I had the most ridiculous run this morning. A goose chased me around the
/// lake — like, committed. Honestly the background noise helps me focus.
///
/// Let's do the bookshop in the Mission this Saturday.
///
/// Detected sounds:
/// • Smoke alarm — 14:03 (96%)
/// ```
extension ConversationRecord {
    /// Renders the transcript as a UTF-8 string ready to hand to `UIActivityViewController`.
    /// Uses the shared `documentParagraphs` grouping so the shared text is identical to what
    /// the user sees on screen.
    var plainTextExport: String {
        var out: [String] = []

        // Header: app + day/time stamp.
        out.append("Earshot — \(HomeView.titleFor(self))")
        out.append(HomeView.metaFor(self))
        out.append("")

        // Body: continuous-prose paragraphs, blank line between each.
        for paragraph in documentParagraphs {
            out.append(paragraph)
            out.append("")
        }

        // Footer: detected urgent sounds, if any. Useful context if the user is forwarding
        // the transcript to someone asking "what happened?"
        if !detections.isEmpty {
            out.append("Detected sounds:")
            let ordered = detections.sorted(by: { $0.detectedAt < $1.detectedAt })
            let timeFmt = DateFormatter()
            timeFmt.dateFormat = "HH:mm"
            for d in ordered {
                let pct = max(0, min(100, Int((d.confidence * 100).rounded())))
                out.append("• \(d.label) — \(timeFmt.string(from: d.detectedAt)) (\(pct)%)")
            }
            out.append("")
        }

        // Trailer — credibility tag so recipients know the source.
        out.append("— captured on-device with Earshot")
        return out.joined(separator: "\n")
    }
}
