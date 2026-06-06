import SwiftUI

/// One stop in the user's journey through the app.
/// The Showcase view drives this enum directly to walk all 16 frames from the export deck.
enum Route: Hashable, Sendable, Identifiable, CaseIterable {
    case onboarding1
    case onboarding2
    case onboarding3
    case modelPrep
    case modelDownloading
    case modelReady
    case home
    case history
    case live11
    case liveGroup
    case alert(SoundDetection)
    case typeToSpeak
    case rewind
    case settings
    case soundSettings
    case languageSettings
    case modelSettings
    case textSizeSettings
    case diarizationSettings
    case privacyPolicy
    case acknowledgements
    /// Carries the conversation's stable UUID so `SummaryView` can look it up via SwiftData.
    /// Nil = "most recent non-empty conversation" (fallback used by the showcase deck and
    /// the Home recents tap path when there's no specific id).
    case summary(UUID?)

    /// `Route` carries an associated value (`.alert(SoundDetection)`), so we hand-roll `allCases`
    /// instead of synthesizing it. The `.alert` slot uses a preview detection — fine, since
    /// `allCases` is only consumed by launch-arg deep-linking and the showcase deck.
    static let allCases: [Route] = [
        .onboarding1, .onboarding2, .onboarding3,
        .modelPrep, .modelDownloading, .modelReady,
        .home, .history,
        .live11, .liveGroup,
        .alert(.preview),
        .typeToSpeak, .rewind,
        .settings, .soundSettings, .languageSettings, .modelSettings, .textSizeSettings, .diarizationSettings,
        .privacyPolicy, .acknowledgements,
        .summary(nil),
    ]

    /// Stable string id. The `.alert` case ignores its associated value so deep-linking by
    /// `id == "alert"` keeps working from launch args / URL schemes.
    var id: String {
        switch self {
        case .onboarding1: "onboarding1"
        case .onboarding2: "onboarding2"
        case .onboarding3: "onboarding3"
        case .modelPrep: "modelPrep"
        case .modelDownloading: "modelDownloading"
        case .modelReady: "modelReady"
        case .home: "home"
        case .history: "history"
        case .live11: "live11"
        case .liveGroup: "liveGroup"
        case .alert: "alert"
        case .typeToSpeak: "typeToSpeak"
        case .rewind: "rewind"
        case .settings: "settings"
        case .soundSettings: "soundSettings"
        case .languageSettings: "languageSettings"
        case .modelSettings: "modelSettings"
        case .textSizeSettings: "textSizeSettings"
        case .diarizationSettings: "diarizationSettings"
        case .privacyPolicy: "privacyPolicy"
        case .acknowledgements: "acknowledgements"
        case .summary: "summary"
        }
    }

    /// Section + label match the export deck's slide labels.
    var section: String {
        switch self {
        case .onboarding1, .onboarding2, .onboarding3: "01 · Onboarding"
        case .modelPrep, .modelDownloading, .modelReady: "01b · Model download"
        case .home, .history: "02 · Home"
        case .live11, .liveGroup: "03 · Live transcription"
        case .alert: "04 · Sound alert"
        case .typeToSpeak, .rewind: "05 · Type-to-speak & Rewind"
        case .settings, .soundSettings, .languageSettings, .modelSettings, .textSizeSettings, .diarizationSettings,
             .privacyPolicy, .acknowledgements, .summary: "06 · Settings & Summary"
        }
    }

    var label: String {
        switch self {
        case .onboarding1: "Step 1 · Every voice"
        case .onboarding2: "Step 2 · Privacy"
        case .onboarding3: "Step 3 · How it works"
        case .modelPrep: "Pre-download"
        case .modelDownloading: "Downloading · 42%"
        case .modelReady: "Ready"
        case .home: "Home"
        case .history: "History"
        case .live11: "1:1 · Coffee with Maya"
        case .liveGroup: "Group · 4 voices"
        case .alert(let detection): detection.sound.label
        case .typeToSpeak: "Type to speak"
        case .rewind: "Rewind / catch up"
        case .settings: "Settings"
        case .soundSettings: "Sound recognition"
        case .languageSettings: "Language"
        case .modelSettings: "Transcription model"
        case .textSizeSettings: "Text size"
        case .diarizationSettings: "Speaker labels"
        case .privacyPolicy: "Privacy policy"
        case .acknowledgements: "Acknowledgements"
        case .summary: "Conversation summary"
        }
    }

    /// The original 16-frame export deck, in order. Showcase mode walks this — NOT every Route,
    /// because new app routes (e.g. languageSettings) shouldn't change the deck composition.
    static let showcaseFrames: [Route] = [
        .onboarding1, .onboarding2, .onboarding3,
        .modelPrep, .modelDownloading, .modelReady,
        .home, .history,
        .live11, .liveGroup,
        .alert(.preview),
        .typeToSpeak, .rewind,
        .settings, .soundSettings, .summary(nil),
    ]
}
