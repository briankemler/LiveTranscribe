import Foundation

/// Turns a `ConversationRecord`'s raw utterance lines into a readable **document** —
/// continuous prose broken into paragraphs at natural pauses.
///
/// Why: each `TranscriptLineRecord` is a Whisper sliding-window emission (~1–3 s of audio),
/// not a sentence or paragraph. Rendering one block per line gives a choppy, stamped wall of
/// fragments. Grouping consecutive lines into paragraphs — splitting only where the speaker
/// actually paused — reads like dictated notes.
///
/// This is the single source of truth for document structure: both `SummaryView` (display)
/// and `plainTextExport` (share sheet) call `documentParagraphs`, so what you read on screen
/// matches what you share. Derived at call time from the stored lines — no schema change, and
/// existing saved transcripts pick up the new format automatically.
extension ConversationRecord {

    /// A new paragraph starts when the silence between one line's end and the next line's
    /// start exceeds this. Lines are ~1 s windows during continuous speech, so contiguous
    /// talk stays in one paragraph; a real "…stopped talking…" gap of 2 s+ breaks it.
    static let paragraphPauseThreshold: TimeInterval = 2.0

    /// The transcript as flowing paragraphs (no speaker labels — per the chosen document
    /// style). Empty array when there are no lines.
    var documentParagraphs: [String] {
        let ordered = lines.sorted(by: { $0.audioStart < $1.audioStart })
        guard !ordered.isEmpty else { return [] }

        var paragraphs: [String] = []
        var current: [String] = []
        var lastEnd: TimeInterval?

        for line in ordered {
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            if let prevEnd = lastEnd, line.audioStart - prevEnd > Self.paragraphPauseThreshold {
                // Pause long enough to start a new paragraph.
                if !current.isEmpty {
                    paragraphs.append(Self.joinFragments(current))
                    current = []
                }
            }
            current.append(text)
            lastEnd = line.audioEnd
        }
        if !current.isEmpty {
            paragraphs.append(Self.joinFragments(current))
        }
        return paragraphs
    }

    /// Join window fragments into one paragraph: single space between fragments, collapse
    /// any accidental double spaces. Whisper fragments are already overlap-deduped upstream
    /// (`LiveSession.newTail`), so this is plain concatenation.
    private static func joinFragments(_ fragments: [String]) -> String {
        fragments
            .joined(separator: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
