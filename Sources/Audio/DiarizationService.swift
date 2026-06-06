import Foundation
import Observation
import OSLog
import SpeakerKit
import ArgmaxCore

private let log = Logger(subsystem: "com.briankemler.LiveTranscribe", category: "DiarizationService")

/// One diarized speaker-activity span produced by the pyannote pipeline: which speaker
/// (cluster id, 0-indexed) held the floor, and over what audio-time window (seconds).
/// This is our own boundary type so SpeakerKit's `DiarizationResult` / `SpeakerSegment`
/// don't leak past the service.
struct DiarizedSegment: Sendable, Hashable {
    /// Pyannote cluster id (0-indexed). These are *local* to a single `diarize` call —
    /// the `SpeakerTimeline` stitcher (next step) maps them onto stable app-wide ids.
    let speakerId: Int
    let start: TimeInterval
    let end: TimeInterval
}

/// Result of one diarization pass over a block of audio.
struct DiarizationOutcome: Sendable {
    let segments: [DiarizedSegment]
    let speakerCount: Int
}

/// Loads the on-device pyannote diarization models (WhisperKit's `SpeakerKit`) and runs
/// speaker diarization over blocks of audio. One shared instance lives on `AppState` so the
/// models load once, mirroring `TranscriptionService`.
///
/// SpeakerKit is **batch-only** — `diarize(samples:)` processes a whole audio array and
/// clusters speakers across it. The live/streaming layer is built on top of this in
/// `LiveSession` + `SpeakerTimeline`; this service just owns the model + the batch call.
///
/// Models come from the `argmaxinc/speakerkit-coreml` Hugging Face repo (~9–22 MB, one
/// quantization variant each of segmenter + embedder + a tiny clusterer) — small enough that
/// we fetch them eagerly alongside Whisper on first launch.
@MainActor
@Observable
final class DiarizationService {

    enum LoadState: Sendable, Equatable {
        case idle
        /// On cellular and the models aren't cached — wait for Wi-Fi rather than spend the
        /// user's data. Resumes when Wi-Fi returns, or immediately via `allowCellular: true`.
        case waitingForWifi
        /// Pulling model weights from Hugging Face. Progress is 0...1.
        case loading(progress: Double)
        /// Download done; Core ML is compiling + loading the models. No progress available.
        case compiling
        case ready
        case failed(message: String)
    }

    enum DiarizationError: Error {
        case modelNotLoaded
    }

    // MARK: - Observed state

    private(set) var loadState: LoadState = .idle

    // MARK: - Private

    /// SpeakerKit's diarizer isn't `Sendable`; it manages its own internal actors/locks. The
    /// box gives Swift 6 strict concurrency the marker it needs without modifying SpeakerKit.
    private final class DiarizerBox: @unchecked Sendable {
        let diarizer: SpeakerKitDiarizer
        init(_ diarizer: SpeakerKitDiarizer) { self.diarizer = diarizer }
    }

    private var box: DiarizerBox?
    private var loadTask: Task<Void, Error>?
    private let network: NetworkMonitor

    init(network: NetworkMonitor) {
        self.network = network
    }

    /// Hugging Face repo the SpeakerKit pyannote models live in.
    static let modelRepo = "argmaxinc/speakerkit-coreml"

    /// Agglomerative cluster-distance threshold passed to pyannote. SpeakerKit's default is 0.6;
    /// we run a touch higher so it merges borderline embeddings instead of spawning spurious
    /// extra speakers — auto speaker-count on short live windows tends to over-segment. Raise to
    /// merge more (fewer speakers), lower to split more (more speakers). Tunable.
    static let clusterThreshold: Float = 0.80

    /// Hub caches the repo snapshot under
    /// `Documents/huggingface/models/argmaxinc/speakerkit-coreml/`.
    nonisolated static var cacheRootURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return docs
            .appendingPathComponent("huggingface")
            .appendingPathComponent("models")
            .appendingPathComponent("argmaxinc")
            .appendingPathComponent("speakerkit-coreml")
    }

    /// Whether the SpeakerKit models are already on disk (so loading needs no network). Used to
    /// decide whether the Wi-Fi gate applies. A non-empty snapshot directory ⇒ cached.
    nonisolated static func modelsCached() -> Bool {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: cacheRootURL.path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        let contents = (try? fm.contentsOfDirectory(atPath: cacheRootURL.path)) ?? []
        return contents.contains { !$0.hasPrefix(".") }
    }

    // MARK: - Model lifecycle

    /// Downloads (first run) + loads the pyannote models. Idempotent — calling again while a
    /// load is in flight awaits the existing task; calling once ready is a no-op.
    ///
    /// Wi-Fi rule mirrors `TranscriptionService`: if the models aren't cached and we're on
    /// cellular, surface `.waitingForWifi` instead of downloading. `allowCellular: true` overrides.
    func loadModel(allowCellular: Bool = false) async throws {
        if case .ready = loadState { return }
        if let existing = loadTask {
            try await existing.value
            return
        }

        let cached = Self.modelsCached()
        if !cached && !allowCellular && !network.isOnWifi {
            loadState = .waitingForWifi
            return
        }

        let task = Task { [self] in
            do {
                // `download: true` lets `downloadModels(progressCallback:)` actually fetch from
                // HF when not cached; when cached, SpeakerKit resolves locally and returns
                // without touching the network. We avoid the high-level `SpeakerKit(_:)`
                // wrapper because its init downloads with no progress callback.
                let diarizer = SpeakerKitDiarizer.pyannote(
                    config: PyannoteConfig(
                        modelRepo: Self.modelRepo,
                        download: true,
                        load: false,
                        verbose: false
                    )
                )

                if !cached {
                    log.info("SpeakerKit models not cached — downloading from \(Self.modelRepo, privacy: .public)")
                    self.loadState = .loading(progress: 0)
                } else {
                    log.info("SpeakerKit models cached — skipping download")
                }

                try await Self.download(diarizer) { [weak self] frac in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if case .loading = self.loadState {
                            self.loadState = .loading(progress: frac)
                        }
                    }
                }

                // Core ML compile/load — no progress callback available.
                self.loadState = .compiling
                try await diarizer.loadModels()

                self.box = DiarizerBox(diarizer)
                self.loadState = .ready
                log.info("SpeakerKit diarizer ready")
            } catch {
                log.error("SpeakerKit load failed: \(String(describing: error))")
                self.loadState = .failed(message: String(describing: error))
                throw error
            }
        }
        self.loadTask = task
        defer { self.loadTask = nil }
        try await task.value
    }

    /// Bridge to `downloadModels(progressCallback:)` from a nonisolated context so the
    /// non-Sendable progress closure stays off MainActor (Swift 6 strict concurrency).
    nonisolated private static func download(
        _ diarizer: SpeakerKitDiarizer,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        // `SpeakerKitDiarizer` adds a `@Sendable` overload of `downloadModels(progressCallback:)`
        // alongside the one inherited from `ModelManager`, so a trailing closure is ambiguous.
        // Call through the superclass (the subclass override just forwards to it).
        try await (diarizer as ModelManager).downloadModels(progressCallback: { p in
            progress(p.fractionCompleted)
        })
    }

    /// Unload the models from memory (e.g. when leaving group mode for a while). Cheap to re-load.
    func unload() async {
        guard let box else { return }
        await box.diarizer.unloadModels()
        self.box = nil
        loadState = .idle
    }

    // MARK: - Diarization

    /// Diarize a contiguous block of 16 kHz mono float samples. Returns per-speaker activity
    /// spans in audio-time seconds (relative to the start of `samples`).
    ///
    /// `numberOfSpeakers` is an optional hint — pass it when the count is known (e.g. the user
    /// said "group of 3"); nil lets pyannote estimate it via clustering.
    func diarize(samples: [Float], numberOfSpeakers: Int? = nil) async throws -> DiarizationOutcome {
        if box == nil { try await loadModel() }
        guard let box else { throw DiarizationError.modelNotLoaded }

        let options = PyannoteDiarizationOptions(
            numberOfSpeakers: numberOfSpeakers,
            clusterDistanceThreshold: Self.clusterThreshold
        )
        let result = try await Task.detached {
            try await box.diarizer.diarize(audioArray: samples, options: options, progressCallback: nil)
        }.value

        let segments = result.segments.compactMap { segment -> DiarizedSegment? in
            guard let speakerId = segment.speaker.speakerId else { return nil }
            return DiarizedSegment(
                speakerId: speakerId,
                start: TimeInterval(segment.startTime),
                end: TimeInterval(segment.endTime)
            )
        }
        return DiarizationOutcome(segments: segments, speakerCount: result.speakerCount)
    }
}
