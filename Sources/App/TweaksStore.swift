import Foundation
import OSLog

private let log = Logger(subsystem: "com.briankemler.LiveTranscribe", category: "TweaksStore")

/// Persists `Tweaks` to `UserDefaults` as a single JSON blob under a versioned key.
/// Versioned so we can ship schema changes without crashing existing testers — a decode failure
/// (key missing, malformed JSON, removed enum case) falls back to `Tweaks()` defaults.
///
/// Used by `AppState.init` (load once) and an `onChange(of: state.tweaks)` at `AppRoot` (save on
/// every change). No throttling — `UserDefaults` writes are cheap and the user is unlikely to be
/// flipping toggles fast enough to matter.
enum TweaksStore {
    static let storageKey = "liveTranscribe.tweaks.v1"

    /// Source of truth for reads/writes. Tests inject an isolated suite; the production path
    /// uses `.standard`. Marked `nonisolated(unsafe)` because Swift 6's strict concurrency
    /// checker doesn't have a per-process atomic-write story for `UserDefaults` references —
    /// in practice this is only mutated from tests (single-threaded) and reads/writes go
    /// through `UserDefaults`'s own thread-safe accessors.
    nonisolated(unsafe) static var defaults: UserDefaults = .standard

    static func load() -> Tweaks {
        guard let data = defaults.data(forKey: storageKey) else { return Tweaks() }
        do {
            return try JSONDecoder().decode(Tweaks.self, from: data)
        } catch {
            log.warning("Failed to decode persisted Tweaks (\(String(describing: error))) — using defaults.")
            return Tweaks()
        }
    }

    static func save(_ tweaks: Tweaks) {
        do {
            let data = try JSONEncoder().encode(tweaks)
            defaults.set(data, forKey: storageKey)
        } catch {
            log.error("Failed to encode Tweaks: \(String(describing: error))")
        }
    }
}
