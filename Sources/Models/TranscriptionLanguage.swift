import Foundation

/// Languages a user can pick for live transcription. The Whisper Small multilingual model
/// supports all 99 Whisper languages out of the box — the curated set here is what we surface in
/// Settings as the user-facing list. "Auto-detect" passes `nil` to WhisperKit so the model picks
/// the language each window; the named cases pin it for faster, more accurate transcription.
enum TranscriptionLanguage: String, CaseIterable, Identifiable, Sendable, Hashable, Codable {
    case auto

    // Top-tier — abundant training data, very high accuracy on Small
    case english
    case spanish
    case french
    case german
    case italian
    case portuguese
    case dutch
    case russian
    case polish

    // Strong support
    case mandarin
    case cantonese
    case japanese
    case korean
    case arabic
    case hindi
    case turkish
    case vietnamese
    case ukrainian
    case swedish
    case indonesian
    case hebrew
    case greek
    case czech
    case thai

    var id: String { rawValue }

    /// Quality tier on Whisper Small. Drives how we group languages on the picker screen.
    enum Tier: Sendable {
        case auto       // Auto-detect — its own slot at the top of the picker
        case excellent  // Abundant training data, top-quality
        case strong     // Strong but slightly less polished
    }

    var tier: Tier {
        switch self {
        case .auto:
            return .auto
        case .english, .spanish, .french, .german, .italian, .portuguese, .dutch, .russian, .polish:
            return .excellent
        default:
            return .strong
        }
    }

    var displayName: String {
        switch self {
        case .auto:       "Auto-detect"
        case .english:    "English"
        case .spanish:    "Spanish"
        case .french:     "French"
        case .german:     "German"
        case .italian:    "Italian"
        case .portuguese: "Portuguese"
        case .dutch:      "Dutch"
        case .russian:    "Russian"
        case .polish:     "Polish"
        case .mandarin:   "Mandarin Chinese"
        case .cantonese:  "Cantonese"
        case .japanese:   "Japanese"
        case .korean:     "Korean"
        case .arabic:     "Arabic"
        case .hindi:      "Hindi"
        case .turkish:    "Turkish"
        case .vietnamese: "Vietnamese"
        case .ukrainian:  "Ukrainian"
        case .swedish:    "Swedish"
        case .indonesian: "Indonesian"
        case .hebrew:     "Hebrew"
        case .greek:      "Greek"
        case .czech:      "Czech"
        case .thai:       "Thai"
        }
    }

    /// Whisper language code (ISO 639-1 in most cases). `nil` for auto-detect.
    var whisperCode: String? {
        switch self {
        case .auto:       nil
        case .english:    "en"
        case .spanish:    "es"
        case .french:     "fr"
        case .german:     "de"
        case .italian:    "it"
        case .portuguese: "pt"
        case .dutch:      "nl"
        case .russian:    "ru"
        case .polish:     "pl"
        case .mandarin:   "zh"
        case .cantonese:  "yue"
        case .japanese:   "ja"
        case .korean:     "ko"
        case .arabic:     "ar"
        case .hindi:      "hi"
        case .turkish:    "tr"
        case .vietnamese: "vi"
        case .ukrainian:  "uk"
        case .swedish:    "sv"
        case .indonesian: "id"
        case .hebrew:     "he"
        case .greek:      "el"
        case .czech:      "cs"
        case .thai:       "th"
        }
    }
}
