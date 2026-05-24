import Testing
import Foundation
@testable import LiveTranscribe

/// `TweaksStore` round-trips the user's settings through `UserDefaults`. These tests use an
/// isolated suite per test so they don't pollute the real `.standard` defaults or each other.
@MainActor
@Suite("TweaksStore")
struct TweaksStoreTests {

    private func isolatedDefaults() -> UserDefaults {
        let suite = "tweaksstore.tests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @Test("Save then load returns identical Tweaks")
    func roundTrip() {
        let defaults = isolatedDefaults()
        TweaksStore.defaults = defaults
        defer { TweaksStore.defaults = .standard }

        var tweaks = Tweaks()
        tweaks.palette = .midnight
        tweaks.textSize = .large
        tweaks.diarization = .smart
        tweaks.transcriptionLanguage = .spanish
        tweaks.transcriptionModel = .tiny
        tweaks.showSpeakerColors = false
        tweaks.armedSounds = ["smoke_detector_smoke_alarm", "doorbell_buzz"]
        tweaks.showDiagnostics = true
        tweaks.showTweaksPanel = true

        TweaksStore.save(tweaks)
        let loaded = TweaksStore.load()
        #expect(loaded == tweaks)
    }

    @Test("Missing key falls back to defaults")
    func missingFallsBack() {
        let defaults = isolatedDefaults()
        TweaksStore.defaults = defaults
        defer { TweaksStore.defaults = .standard }

        let loaded = TweaksStore.load()
        #expect(loaded == Tweaks())
    }

    @Test("Corrupt JSON falls back to defaults")
    func corruptFallsBack() {
        let defaults = isolatedDefaults()
        TweaksStore.defaults = defaults
        defer { TweaksStore.defaults = .standard }

        defaults.set(Data("not json".utf8), forKey: TweaksStore.storageKey)
        let loaded = TweaksStore.load()
        #expect(loaded == Tweaks())
    }

    /// JSON written by an earlier build with fewer fields must still decode. New fields fill
    /// in with defaults rather than poisoning the whole blob — that's the forward-compat
    /// behavior `Tweaks.init(from:)` provides.
    @Test("Old JSON (missing new keys) preserves known fields and defaults the rest")
    func forwardCompatibleDecode() {
        let defaults = isolatedDefaults()
        TweaksStore.defaults = defaults
        defer { TweaksStore.defaults = .standard }

        // Mimic a JSON blob from a build that knew about palette/textSize/showSpeakerColors
        // but not translateToEnglish or soundRecognitionEnabled.
        let legacyJSON = """
        {
            "palette": "midnight",
            "textSize": "large",
            "showSpeakerColors": false
        }
        """
        defaults.set(Data(legacyJSON.utf8), forKey: TweaksStore.storageKey)

        let loaded = TweaksStore.load()
        #expect(loaded.palette == .midnight)
        #expect(loaded.textSize == .large)
        #expect(loaded.showSpeakerColors == false)
        // New keys fall back to current defaults.
        #expect(loaded.translateToEnglish == false)
        #expect(loaded.soundRecognitionEnabled == true)
    }
}
