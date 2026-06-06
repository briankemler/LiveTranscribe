import Foundation

/// Developer-only live knobs for the software speaker-separation (diarization) pipeline. These
/// are normally hardcoded constants in `DiarizationService` / `LiveSession`; surfacing them behind
/// the hidden Developer gate lets us tune on-device with real audio (the only place diarization
/// can be judged) without a rebuild → upload → TestFlight round-trip. Once good values are found,
/// they get baked back in as the defaults below.
///
/// NOT user-facing: the user-facing control is the "How many people?" picker (`groupSpeakerCount`),
/// which is the primary quality lever. These are the secondary knobs.
struct DiarizationTuning: Codable, Equatable, Sendable {
    /// Agglomerative cluster-distance threshold for pyannote. Higher = merges more (fewer speakers),
    /// lower = splits more. SpeakerKit default is 0.6; we run higher to curb over-segmentation.
    var clusterThreshold: Double = 0.80
    /// Trailing span (seconds) diarized each pass. Longer = pyannote re-clusters more of the
    /// conversation by voice (better re-ID of returning speakers) but more per-pass compute.
    var windowSeconds: Double = 90
    /// How often (seconds of audio) a diarization pass runs. Smaller = more responsive but hotter.
    var strideSeconds: Double = 5
    /// Minimum speech (seconds) an unmatched cluster must accumulate before it earns a new stable
    /// speaker pill — suppresses brief mis-clusters.
    var minNewSpeakerSeconds: Double = 2.5

    static let defaults = DiarizationTuning()

    // Slider ranges for the dev panel.
    static let clusterThresholdRange: ClosedRange<Double> = 0.50...0.95
    static let windowRange: ClosedRange<Double> = 24...120
    static let strideRange: ClosedRange<Double> = 3...10
    static let minNewSpeakerRange: ClosedRange<Double> = 0.5...5.0

    private static let key = "liveTranscribe.diarizationTuning.v1"

    /// Load persisted tuning (so values survive relaunches while iterating); defaults on miss/corrupt.
    static func load() -> DiarizationTuning {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(DiarizationTuning.self, from: data)
        else { return .defaults }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
