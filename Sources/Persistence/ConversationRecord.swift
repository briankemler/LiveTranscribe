import Foundation
import SwiftData

/// Persistent record of one live-transcription session. Created when `LiveSession.start()`
/// succeeds; finalized when the user leaves the Live screen (or kills the app).
///
/// One conversation owns many `TranscriptLineRecord`s (the captions) and many
/// `SoundDetectionRecord`s (every urgent sound that fired during the session). Both cascade-
/// delete with the parent so wiping a conversation cleans everything up.
@Model
final class ConversationRecord {
    /// Stable UUID we route by — `Route.summary(UUID)` resolves a conversation via this.
    /// Using a UUID lets the Route enum stay `Hashable` without leaking SwiftData types
    /// through the navigation layer.
    @Attribute(.unique) var id: UUID
    /// `"oneToOne"` or `"group"`. Stored raw so we don't depend on `LiveMode`'s enum layout
    /// across versions.
    var modeRaw: String
    var startedAt: Date
    /// Wall-clock end. Nil while the session is still live.
    var endedAt: Date?
    /// Convenience: true if any urgent sound fired during this session.
    var hadUrgentDetection: Bool
    /// Build-14: user has bookmarked this conversation via the captions screen star button.
    /// Surfaced through `HistoryView`'s "Starred" filter and the Settings → Transcripts row.
    var isStarred: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \TranscriptLineRecord.conversation)
    var lines: [TranscriptLineRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \SoundDetectionRecord.conversation)
    var detections: [SoundDetectionRecord] = []

    init(
        id: UUID = UUID(),
        modeRaw: String,
        startedAt: Date,
        endedAt: Date? = nil,
        hadUrgentDetection: Bool = false
    ) {
        self.id = id
        self.modeRaw = modeRaw
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.hadUrgentDetection = hadUrgentDetection
    }

    var mode: LiveMode {
        modeRaw == "group" ? .group : .oneToOne
    }

    /// Display-time duration, capped at the in-progress window if `endedAt` is still nil.
    var duration: TimeInterval {
        let end = endedAt ?? Date()
        return max(0, end.timeIntervalSince(startedAt))
    }

    /// Distinct speaker IDs touched during this conversation.
    var speakerCount: Int {
        Set(lines.map { $0.speakerId }).count
    }
}

/// One finalized caption line.
@Model
final class TranscriptLineRecord {
    @Attribute(.unique) var id: UUID
    /// Canonical speaker key — "You", "Maya", "Speaker 1", "Speaker 2", etc. Matches
    /// `Speaker.id` so we can rebuild a `Speaker` via `Speaker.find(...)`.
    var speakerId: String
    var speakerDisplayName: String
    var speakerInitial: String
    /// Raw value of `Speaker.SpeakerColorRole` ("a"…"e"). Stored as a string so we don't
    /// fight SwiftData over the enum.
    var speakerColorRoleRaw: String
    var text: String
    /// Audio-time seconds since session start. Drives Rewind seek + Summary timestamps.
    var audioStart: TimeInterval
    var audioEnd: TimeInterval
    /// Whether the user starred this line in Summary.
    var isStarred: Bool

    var conversation: ConversationRecord?

    init(
        id: UUID = UUID(),
        speakerId: String,
        speakerDisplayName: String,
        speakerInitial: String,
        speakerColorRoleRaw: String,
        text: String,
        audioStart: TimeInterval,
        audioEnd: TimeInterval,
        isStarred: Bool = false
    ) {
        self.id = id
        self.speakerId = speakerId
        self.speakerDisplayName = speakerDisplayName
        self.speakerInitial = speakerInitial
        self.speakerColorRoleRaw = speakerColorRoleRaw
        self.text = text
        self.audioStart = audioStart
        self.audioEnd = audioEnd
        self.isStarred = isStarred
    }

    /// Rehydrate a `Speaker` value type from the record. Keeps the UI side untouched.
    var speaker: Speaker {
        Speaker(
            id: speakerId,
            displayName: speakerDisplayName,
            initial: speakerInitial,
            colorRole: Speaker.SpeakerColorRole.from(raw: speakerColorRoleRaw)
        )
    }
}

/// One urgent-sound detection that fired during the session.
@Model
final class SoundDetectionRecord {
    @Attribute(.unique) var id: UUID
    /// Apple classifier identifier (e.g. `"smoke_detector_smoke_alarm"`). Matches
    /// `SoundCatalog.byID` so we can look up icon + label.
    var classifierID: String
    /// Snapshot of the chip label at the time of detection. Lets us render historical data
    /// even if the catalog changes.
    var label: String
    var icon: String
    var confidence: Float
    var detectedAt: Date

    var conversation: ConversationRecord?

    init(
        id: UUID = UUID(),
        classifierID: String,
        label: String,
        icon: String,
        confidence: Float,
        detectedAt: Date
    ) {
        self.id = id
        self.classifierID = classifierID
        self.label = label
        self.icon = icon
        self.confidence = confidence
        self.detectedAt = detectedAt
    }

    var detection: SoundDetection {
        // Build-16: `UrgentSound` now uses `chipID` + `classifierIDs: [String]`. For
        // persisted single-ID records we just reconstruct a 1-ID chip.
        SoundDetection(
            sound: UrgentSound.single(classifierID, icon: icon, label: label),
            confidence: confidence,
            detectedAt: detectedAt
        )
    }
}

extension Speaker.SpeakerColorRole {
    var raw: String {
        switch self {
        case .a: "a"
        case .b: "b"
        case .c: "c"
        case .d: "d"
        case .e: "e"
        }
    }

    static func from(raw: String) -> Speaker.SpeakerColorRole {
        switch raw {
        case "b": .b
        case "c": .c
        case "d": .d
        case "e": .e
        default:  .a
        }
    }
}
