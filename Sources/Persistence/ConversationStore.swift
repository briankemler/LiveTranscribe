import Foundation
import SwiftData
import OSLog

private let log = Logger(subsystem: "com.briankemler.LiveTranscribe", category: "ConversationStore")

/// Builds the app's `ModelContainer` and exposes a small main-actor API for the rest of the
/// app. `LiveSession` writes into it as captions and detections land; `HomeView` /
/// `HistoryView` / `SummaryView` read via `@Query` or the `fetchConversation(id:)` helper.
@MainActor
enum ConversationStore {

    /// Build the production container. Falls back to an in-memory container if disk-backed
    /// storage fails (corrupt store, bad migration) — better to ship an empty history than to
    /// crash on launch.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            ConversationRecord.self,
            TranscriptLineRecord.self,
            SoundDetectionRecord.self,
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            log.error("Failed to build disk-backed ModelContainer (\(String(describing: error))). Falling back to in-memory.")
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // The in-memory fallback is guaranteed by Apple to succeed for the same schema —
            // a failure here would mean the schema itself is broken, which is a programmer
            // error worth crashing on so we catch it in CI.
            return try! ModelContainer(for: schema, configurations: config)
        }
    }

    /// Repair conversations orphaned by a crash / force-quit mid-session: their `endedAt` was
    /// never set, so any duration display keeps growing against `Date()` forever. Backfill a
    /// sane end (start + last line's audio offset, or the start itself for empty records) and
    /// delete line-less, detection-less ghosts outright. Call once at launch, BEFORE any new
    /// session starts (so the live session's own nil `endedAt` is never touched).
    static func repairUnfinishedConversations(in context: ModelContext) {
        let descriptor = FetchDescriptor<ConversationRecord>(
            predicate: #Predicate { $0.endedAt == nil }
        )
        guard let orphans = try? context.fetch(descriptor), !orphans.isEmpty else { return }
        for record in orphans {
            if record.lines.isEmpty && record.detections.isEmpty {
                context.delete(record)
            } else {
                let lastOffset = record.lines.map(\.audioEnd).max() ?? 0
                record.endedAt = record.startedAt.addingTimeInterval(max(0, lastOffset))
            }
        }
        try? context.save()
        log.info("Repaired \(orphans.count) unfinished conversation record(s) from a prior run.")
    }

    /// Look up a conversation by its routing UUID. Used by `SummaryView` and `RewindView`.
    static func fetchConversation(id: UUID, in context: ModelContext) -> ConversationRecord? {
        var descriptor = FetchDescriptor<ConversationRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Most-recently-started conversation that has at least one line. Used by `RewindView`
    /// when no specific id is supplied. Returns nil if the user has never run a session.
    static func mostRecentNonEmpty(in context: ModelContext) -> ConversationRecord? {
        var descriptor = FetchDescriptor<ConversationRecord>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 8
        let recents = (try? context.fetch(descriptor)) ?? []
        return recents.first(where: { !$0.lines.isEmpty })
    }
}
