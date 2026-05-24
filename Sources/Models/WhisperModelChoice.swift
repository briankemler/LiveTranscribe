import Foundation

/// The Whisper models the user can pick in Settings. Each entry maps to a downloadable Core ML
/// model from Argmax's `argmaxinc/whisperkit-coreml` Hugging Face repo. All sizes below are the
/// disk footprint after download; the *binary* footprint added to the app is zero — models are
/// fetched on first use of that model and cached in the app's documents directory.
enum WhisperModelChoice: String, CaseIterable, Identifiable, Sendable, Hashable, Codable {
    case tiny
    case base
    case small

    // NOTE: Large v3 and Large v3 Turbo are intentionally absent from v1. They worked in
    // controlled tests but in practice are too slow on iPhone (15+ min compile on first load,
    // sub-realtime inference even on A18 Pro) for a "live" caption experience. Re-introducing
    // them needs a different pipeline — 30 s VAD-segmented windows instead of 3 s sliding —
    // which is v2 work.

    var id: String { rawValue }

    /// The exact model identifier WhisperKit accepts and pulls from Hugging Face.
    var whisperKitName: String {
        switch self {
        case .tiny:  "openai_whisper-tiny"
        case .base:  "openai_whisper-base"
        case .small: "openai_whisper-small"
        }
    }

    var displayName: String {
        switch self {
        case .tiny:  "Whisper Tiny"
        case .base:  "Whisper Base"
        case .small: "Whisper Small"
        }
    }

    /// Approximate disk size in megabytes once downloaded. Used for "Will download …" status text.
    var sizeMB: Int {
        switch self {
        case .tiny:  39
        case .base:  74
        case .small: 244
        }
    }

    /// One-line description: who this model is for.
    var blurb: String {
        switch self {
        case .tiny:
            "Fastest, smallest. Misses uncommon words. Good for testing."
        case .base:
            "Cheap upgrade from Tiny. Works fine on older phones."
        case .small:
            "Best balance for daily use. Real-time on A17 and faster."
        }
    }

    /// Coarse quality tier — drives the section grouping in the picker.
    enum Tier: Sendable {
        case light, balanced
    }

    var tier: Tier {
        switch self {
        case .tiny, .base: .light
        case .small:       .balanced
        }
    }

    /// Formatted size string for UI: "244 MB" or "1.5 GB".
    var sizeLabel: String {
        if sizeMB >= 1000 {
            let gb = Double(sizeMB) / 1000
            return String(format: "%.1f GB", gb)
        }
        return "\(sizeMB) MB"
    }
}
