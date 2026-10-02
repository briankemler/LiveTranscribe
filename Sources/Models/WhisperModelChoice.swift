import Foundation

/// The Whisper models the user can pick in Settings. Each entry maps to a downloadable Core ML
/// model from Argmax's `argmaxinc/whisperkit-coreml` Hugging Face repo. All sizes below are the
/// disk footprint after download; the *binary* footprint added to the app is zero — models are
/// fetched on first use of that model and cached in the app's documents directory.
enum WhisperModelChoice: String, CaseIterable, Identifiable, Sendable, Hashable, Codable {
    case tiny
    case base
    case small
    /// Large v3 Turbo, quantized (626 MB). Shipped un-gated in 1.0.2 (owner decision) as the
    /// max-accuracy option — biggest win is long-tail languages (e.g. Swedish ~15% → ~8% WER
    /// vs Small). Still RAM-gated (≥6 GB, `isSupportedOnThisDevice`): the full-precision large
    /// models were rejected for v1 as sub-realtime (the pipeline re-runs the whole encoder
    /// every ~1 s pass on 30 s-padded input), and low-RAM devices would jetsam regardless.
    /// REMOVAL (if field feedback says it can't keep up): delete this case + the
    /// "MAX ACCURACY" section in ModelSettingsView. Persisted tweaks survive — Tweaks'
    /// per-field decoder falls back to `.base` on an unknown raw value — but map
    /// largeTurbo → .small explicitly in TweaksStore.load for a kinder downgrade.
    case largeTurbo

    var id: String { rawValue }

    /// The exact model identifier WhisperKit accepts and pulls from Hugging Face.
    var whisperKitName: String {
        switch self {
        case .tiny:  "openai_whisper-tiny"
        case .base:  "openai_whisper-base"
        case .small: "openai_whisper-small"
        case .largeTurbo: "openai_whisper-large-v3-v20240930_626MB"
        }
    }

    var displayName: String {
        switch self {
        case .tiny:  "Whisper Tiny"
        case .base:  "Whisper Base"
        case .small: "Whisper Small"
        case .largeTurbo: "Whisper Large Turbo"
        }
    }

    /// Approximate disk size in megabytes once downloaded. Used for "Will download …" status text.
    var sizeMB: Int {
        switch self {
        case .tiny:  39
        case .base:  74
        case .small: 244
        case .largeTurbo: 626
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
        case .largeTurbo:
            "Most accurate — the biggest gains are for less common languages. Needs a recent iPhone; the first load takes a few minutes."
        }
    }

    /// Coarse quality tier — drives the section grouping in the picker.
    enum Tier: Sendable {
        case light, balanced, max
    }

    var tier: Tier {
        switch self {
        case .tiny, .base: .light
        case .small:       .balanced
        case .largeTurbo:  .max
        }
    }

    /// Whether this device can realistically hold the model. Large Turbo needs ~1–1.5 GB peak
    /// alongside pyannote; the iOS 17 floor includes 3–4 GB-RAM phones where that jetsams.
    /// 5.5 GB threshold ≈ "6 GB-class or better" after the OS's share of reported memory.
    var isSupportedOnThisDevice: Bool {
        switch self {
        case .tiny, .base, .small: true
        case .largeTurbo: ProcessInfo.processInfo.physicalMemory >= 5_500_000_000
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
