import SwiftUI

/// Visual tweaks the user can flip from in-app Settings (or the developer Tweaks panel).
/// `Codable` so `TweaksStore` can persist the whole struct as a JSON blob in `UserDefaults`.
struct Tweaks: Sendable, Equatable, Codable {
    var palette: PaletteID = .warm
    var textSize: TextSize = .regular
    var diarization: Diarization = .auto
    /// Expected number of speakers in group mode. A fixed count is handed to pyannote as a hard
    /// constraint (`numberOfSpeakers`) AND caps the stable-speaker timeline, which is far more
    /// stable than letting it auto-estimate on short live windows (which over-splits and "keeps
    /// cycling" new speakers). Defaults to `.two` — the most reliable case; users bump to 3/4 from
    /// the captions Quick Settings sheet. `.auto` keeps estimation (capped at 4). Persisted.
    var groupSpeakerCount: GroupSpeakerCount = .two
    /// Captions screen layout. `.focus` (default) = the teleprompter view: one big current
    /// line + one dim previous line. `.feed` ("Star Wars" internally) = a chat-style
    /// scrolling feed that keeps several past utterances visible and auto-scrolls upward as
    /// new lines land. Picked in the captions Quick Settings sheet.
    var captionLayout: CaptionLayout = .focus
    /// Language pinned for Whisper transcription. `.auto` lets the model detect per window.
    var transcriptionLanguage: TranscriptionLanguage = .auto
    /// When true, Whisper runs in `.translate` mode: any source language → English captions.
    /// When false (default), captions are in the spoken language. Whisper translate is one-
    /// directional (any → English), so this is a binary toggle, not a target-language picker.
    var translateToEnglish: Bool = false
    /// Which Whisper model variant the user has chosen. Switching this in Settings triggers an
    /// on-device reload (and a download, the first time that model is picked).
    var transcriptionModel: WhisperModelChoice = .small
    var showSpeakerColors: Bool = true
    /// Rev-2 captions: drives the right-margin sound tag on the captions screen. Default off
    /// until real ambient-sound detection (non-urgent SoundAnalysis categories) is wired up;
    /// flipping it on today shows a placeholder so the toggle's effect is visible.
    var showAmbientSounds: Bool = false
    /// Rev-2 captions: when false, `AlertView` skips its `.error` haptic. The VoiceOver
    /// announcement still fires regardless — this only gates the buzz.
    var vibrateOnAlerts: Bool = true
    /// Master enable for the urgent-sound recognizer. When false, `LiveSession` won't start
    /// the `SNAudioStreamAnalyzer` at all — even sounds that are armed in `armedSounds` won't
    /// fire. Lets the user kill the whole feature without having to disarm every chip.
    var soundRecognitionEnabled: Bool = true
    /// Apple SoundAnalysis classifier IDs the user wants alerted on. Defaults to the 5 urgent
    /// sounds in `SoundCatalog.urgent`. Stored as raw IDs so we can persist forward-compatibly
    /// even if the user-facing chip set grows. Soft-capped at `SoundCatalog.maxUrgent` (6) by
    /// the picker UI — the model itself doesn't enforce, so a corrupt persisted set with more
    /// IDs would still load and all those urgent sounds would fire.
    ///
    /// Build-16: the matching `armedAmbientSounds` field was removed. Non-urgent detection is
    /// now driven entirely from `SoundCatalog.allNonUrgentIDs` whenever the master
    /// `showAmbientSounds` toggle is on — no per-sound selection on the ambient side.
    var armedSounds: Set<String> = SoundCatalog.defaultArmedIDs
    /// Developer-only: shows the chunks/buf/rms/passes pill at the top of the Live screen.
    /// Off by default; toggle from Settings → Developer.
    var showDiagnostics: Bool = false
    /// Developer-only: shows the floating side-tab that opens the Tweaks panel
    /// (palette / text size / diarization / showcase deck). Hidden from external testers by
    /// default. Toggle from Settings → Developer.
    var showTweaksPanel: Bool = false

    /// Captions screen layout mode. See `Tweaks.captionLayout`.
    enum CaptionLayout: String, CaseIterable, Sendable, Identifiable, Codable {
        /// Teleprompter: big current line + one dim previous line. The original Rev-2 layout.
        case focus
        /// Chat-style scrolling feed (internal codename "Star Wars"): several past utterances
        /// stacked with spacing, newest at the bottom, auto-scrolls up as lines land.
        case feed
        var id: String { rawValue }
        var label: String {
            switch self {
            case .focus: "Focus"
            case .feed: "Feed"
            }
        }
    }

    enum TextSize: String, CaseIterable, Sendable, Identifiable, Codable {
        case small, regular, large, huge
        var id: String { rawValue }
        var scale: CGFloat {
            switch self {
            case .small: 0.78
            case .regular: 1.0
            case .large: 1.18
            case .huge: 1.42
            }
        }
        var label: String {
            switch self {
            case .small: "Small"
            case .regular: "Regular"
            case .large: "Large"
            case .huge: "Huge"
            }
        }
    }

    /// Expected speaker count for group-mode diarization. See `Tweaks.groupSpeakerCount`.
    enum GroupSpeakerCount: String, CaseIterable, Sendable, Identifiable, Codable {
        case auto, one, two, three, four
        var id: String { rawValue }
        /// The hint handed to pyannote — nil for `.auto` (estimate the count).
        var count: Int? {
            switch self {
            case .auto: nil
            case .one: 1
            case .two: 2
            case .three: 3
            case .four: 4
            }
        }
        var label: String {
            switch self {
            case .auto: "Auto"
            case .one: "1"
            case .two: "2"
            case .three: "3"
            case .four: "4"
            }
        }
    }

    enum Diarization: String, CaseIterable, Sendable, Identifiable, Codable {
        case auto, smart, off
        var id: String { rawValue }
        var label: String {
            switch self {
            case .auto: "Auto"
            case .smart: "Smart"
            case .off: "Off"
            }
        }
        var blurb: String {
            switch self {
            case .auto: "Real names"
            case .smart: "Speaker 1, 2, 3…"
            case .off: "No labels"
            }
        }
    }

}

// MARK: - Forward-compatible decoding

extension Tweaks {
    /// Custom decoder so adding a new field to `Tweaks` doesn't reset every tester's settings.
    /// Each key falls back to the property's default when missing. Synthesized `Codable`
    /// decoding throws on missing required keys, which would force `TweaksStore.load()` to
    /// drop the whole blob; this implementation keeps the unaffected fields intact.
    /// Lives in an extension so the synthesized no-arg / memberwise inits stay intact.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Tweaks()
        self.palette               = try c.decodeIfPresent(PaletteID.self,           forKey: .palette)               ?? defaults.palette
        self.textSize              = try c.decodeIfPresent(TextSize.self,            forKey: .textSize)              ?? defaults.textSize
        self.diarization           = try c.decodeIfPresent(Diarization.self,         forKey: .diarization)           ?? defaults.diarization
        self.groupSpeakerCount     = try c.decodeIfPresent(GroupSpeakerCount.self,   forKey: .groupSpeakerCount)     ?? defaults.groupSpeakerCount
        self.captionLayout         = try c.decodeIfPresent(CaptionLayout.self,       forKey: .captionLayout)         ?? defaults.captionLayout
        self.transcriptionLanguage = try c.decodeIfPresent(TranscriptionLanguage.self, forKey: .transcriptionLanguage) ?? defaults.transcriptionLanguage
        self.translateToEnglish    = try c.decodeIfPresent(Bool.self,                forKey: .translateToEnglish)    ?? defaults.translateToEnglish
        self.transcriptionModel    = try c.decodeIfPresent(WhisperModelChoice.self,  forKey: .transcriptionModel)    ?? defaults.transcriptionModel
        self.showSpeakerColors     = try c.decodeIfPresent(Bool.self,                forKey: .showSpeakerColors)     ?? defaults.showSpeakerColors
        self.showAmbientSounds     = try c.decodeIfPresent(Bool.self,                forKey: .showAmbientSounds)     ?? defaults.showAmbientSounds
        self.vibrateOnAlerts       = try c.decodeIfPresent(Bool.self,                forKey: .vibrateOnAlerts)       ?? defaults.vibrateOnAlerts
        self.soundRecognitionEnabled = try c.decodeIfPresent(Bool.self,              forKey: .soundRecognitionEnabled) ?? defaults.soundRecognitionEnabled
        self.armedSounds           = try c.decodeIfPresent(Set<String>.self,         forKey: .armedSounds)           ?? defaults.armedSounds
        // `armedAmbientSounds` was removed in build 16. JSON blobs from build 14/15 that
        // still contain that key are simply ignored — no behavior change for the user
        // since non-urgent detection is now always-armed via SoundCatalog.allNonUrgentIDs.
        self.showDiagnostics       = try c.decodeIfPresent(Bool.self,                forKey: .showDiagnostics)       ?? defaults.showDiagnostics
        self.showTweaksPanel       = try c.decodeIfPresent(Bool.self,                forKey: .showTweaksPanel)       ?? defaults.showTweaksPanel
    }
}

private struct TweaksKey: EnvironmentKey {
    static let defaultValue: Tweaks = Tweaks()
}

extension EnvironmentValues {
    var tweaks: Tweaks {
        get { self[TweaksKey.self] }
        set { self[TweaksKey.self] = newValue }
    }
}
