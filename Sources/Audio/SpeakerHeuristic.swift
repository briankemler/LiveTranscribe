import Foundation

/// Pause-based speaker labeller. Not real diarization — we don't model voice embeddings or
/// look at the audio at all. The rule is just: "long enough silence means a new speaker probably
/// took the floor." Cheap, no extra ML download, surprisingly OK at conversational pace.
///
/// In 1:1 mode: every line stays under the same rolling speaker — labels are nominal.
/// In group mode: a `silenceBeforeMs > pauseThresholdMs` rotates to the next "Speaker N" (1-indexed).
///
/// V2 candidate: replace with pyannote-style speaker embeddings on each window and cluster.
struct SpeakerHeuristic {
    var mode: LiveMode
    var pauseThresholdMs: Int = 1200
    /// How many distinct speakers we're willing to label before wrapping back to 1.
    /// Matches the design's group-of-4 (Jordan, Maya, Priya, You) ceiling.
    var maxSpeakers: Int = 4

    /// Last speaker index used (1-indexed). Mutated as new partials arrive.
    private(set) var currentSpeakerIndex: Int = 1

    /// Convert one transcript partial into a finished `TranscriptLine`. Side effect: advances
    /// `currentSpeakerIndex` if the pause-since-last is long enough and we're in group mode.
    mutating func line(for partial: PartialTranscript) -> TranscriptLine {
        if mode == .group, partial.silenceBeforeMs > pauseThresholdMs {
            currentSpeakerIndex = (currentSpeakerIndex % maxSpeakers) + 1
        }
        let speaker: Speaker = {
            switch mode {
            case .oneToOne:
                // 1:1 with the user holding the phone: every line is "the other person".
                // We don't know their name, so use a generic placeholder that picks up the
                // accent color via colorRole .b (sage — same as Maya in the prototype).
                return Speaker(
                    id: "other",
                    displayName: "·",
                    initial: "•",
                    colorRole: .b
                )
            case .group:
                return Speaker.numbered(currentSpeakerIndex)
            }
        }()
        return TranscriptLine(speaker: speaker, text: partial.text, emphasis: nil, timestamp: nil)
    }
}

extension Speaker {
    /// Speaker N factory — used by the pause-based heuristic in group mode. Cycles through
    /// colorRoles A-D so each labelled speaker gets a different accent.
    static func numbered(_ n: Int) -> Speaker {
        let roles: [SpeakerColorRole] = [.c, .b, .d, .a]
        let role = roles[(n - 1) % roles.count]
        return Speaker(
            id: "Speaker \(n)",
            displayName: "Speaker \(n)",
            initial: "\(n)",
            colorRole: role
        )
    }

    /// Microphone factory — used by group mode when a multi-channel input device is connected,
    /// so each line is attributed to the physical mic (channel) that was loudest. `n` is the
    /// 1-indexed mic number. Reuses the same A–D color cycle as `numbered(_:)` so a mic keeps a
    /// stable accent across pills and transcript lines.
    static func mic(_ n: Int) -> Speaker {
        let roles: [SpeakerColorRole] = [.c, .b, .d, .a]
        let role = roles[(n - 1) % roles.count]
        return Speaker(
            id: "Mic \(n)",
            displayName: "Mic \(n)",
            initial: "\(n)",
            colorRole: role
        )
    }
}
