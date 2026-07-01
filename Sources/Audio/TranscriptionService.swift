import Foundation
import Observation
import OSLog
import WhisperKit

private let log = Logger(subsystem: "com.briankemler.LiveTranscribe", category: "TranscriptionService")

/// One emitted unit of transcribed speech. The streaming path emits these as the speaker talks;
/// `isFinal` flips to true once the model is confident about the segment (e.g. on a long pause).
struct PartialTranscript: Sendable, Hashable {
    let id: UUID
    let text: String
    let isFinal: Bool
    /// Audio time of the first sample that contributed to this transcript, in seconds.
    let audioStart: TimeInterval
    let audioEnd: TimeInterval
    /// Approximate silence duration (ms) immediately before this segment started. Used by the
    /// pause-based speaker heuristic in group mode. Zero for the first segment of a session.
    let silenceBeforeMs: Int

    init(
        id: UUID = UUID(),
        text: String,
        isFinal: Bool,
        audioStart: TimeInterval,
        audioEnd: TimeInterval,
        silenceBeforeMs: Int = 0
    ) {
        self.id = id
        self.text = text
        self.isFinal = isFinal
        self.audioStart = audioStart
        self.audioEnd = audioEnd
        self.silenceBeforeMs = silenceBeforeMs
    }
}

/// Loads the on-device Whisper model and runs transcription. There's one of these in `AppState`
/// so the model is loaded once for the whole app, not re-loaded every time a Live screen opens.
///
/// This service intentionally does NOT do mic capture itself — it consumes audio from
/// `AudioCaptureService`. Keeping the two split means we can unit-test transcription against
/// a WAV fixture without touching `AVAudioEngine` at all.
@MainActor
@Observable
final class TranscriptionService {

    enum LoadState: Sendable, Equatable {
        case idle
        /// Wi-Fi unavailable; the model needs ~244 MB pulled from Hugging Face. We pause here
        /// rather than burn the user's cellular allowance. Resumes automatically when Wi-Fi
        /// returns, or instantly if the user taps "Download over cellular now".
        case waitingForWifi
        /// Pulling model weights from Hugging Face. Progress is 0...1.
        case loading(progress: Double)
        /// Download done; Core ML is compiling the model for the Neural Engine and warming the
        /// inference pipeline. This phase has no progress (Core ML doesn't expose it) and on
        /// larger models can take 30-90 s on first launch.
        case compiling
        case ready
        case failed(message: String)
    }

    enum TranscriptionError: Error {
        case modelNotLoaded
        case audioReadFailed(any Error)
    }

    /// Fallback model when none is passed — Whisper Base (~74 MB): a small, fast first download.
    /// The actual model normally comes from the user's saved choice (see `AppState`); overridable
    /// via `setModel(_:)` in Settings (Small is more accurate).
    static let defaultModelName = "openai_whisper-base"

    // MARK: - Observed state

    private(set) var loadState: LoadState = .idle
    /// The model name we *want* loaded. May differ from what's actually loaded if a switch is in flight.
    private(set) var modelName: String
    /// The model name we last successfully loaded — i.e. what `transcribe(...)` is using right now.
    /// Nil until the first load completes.
    private(set) var loadedModelName: String?
    /// Whisper model names (e.g. "openai_whisper-small") currently cached on disk and ready to use
    /// without re-downloading. Populated by scanning the cache directory at init + after each load
    /// + after each removeModel.
    private(set) var downloadedModels: Set<String> = []

    // MARK: - Private

    /// WhisperKit isn't `Sendable`, but its transcribe methods manage their own internal locks —
    /// safe to await across actor boundaries in practice. The box gives Swift 6 strict-concurrency
    /// the marker it needs without us having to reach into WhisperKit to mark it Sendable.
    private final class KitBox: @unchecked Sendable {
        let kit: WhisperKit
        init(_ kit: WhisperKit) { self.kit = kit }
    }

    private var whisperBox: KitBox?
    private var loadTask: Task<Void, Error>?
    /// Network reachability — read before a download to decide whether to gate on Wi-Fi.
    private let network: NetworkMonitor

    init(network: NetworkMonitor, modelName: String = TranscriptionService.defaultModelName) {
        self.network = network
        self.modelName = modelName
        self.downloadedModels = Self.scanCachedModels()
    }

    /// Path WhisperKit caches downloaded models to.
    /// `Documents/huggingface/models/argmaxinc/whisperkit-coreml/<model-name>/`.
    nonisolated static var cacheRootURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return docs
            .appendingPathComponent("huggingface")
            .appendingPathComponent("models")
            .appendingPathComponent("argmaxinc")
            .appendingPathComponent("whisperkit-coreml")
    }

    /// Scan the WhisperKit cache for downloaded model folders. Returns the set of WhisperKit model
    /// names that are already on disk and can load without re-downloading.
    nonisolated static func scanCachedModels() -> Set<String> {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: cacheRootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return Set(entries.compactMap { url -> String? in
            let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey])
            guard resourceValues?.isDirectory == true else { return nil }
            return url.lastPathComponent
        })
    }

    /// The compiled Core ML components every WhisperKit model folder must contain to load. A
    /// folder can exist but be missing these if a download was interrupted (network drop, app
    /// killed mid-download) — which is exactly the App Review failure: the folder was present so
    /// we skipped re-downloading, then `WhisperKit(...)` threw "Model file not found at …
    /// MelSpectrogram.mlmodelc". We check for these before trusting an on-disk model.
    nonisolated private static let requiredModelComponents = [
        "MelSpectrogram.mlmodelc",
        "AudioEncoder.mlmodelc",
        "TextDecoder.mlmodelc",
    ]

    /// True only if `name`'s folder exists AND contains every required compiled component as a
    /// non-empty directory. A `false` here means "(re)download to repair," not just "absent."
    nonisolated static func isModelComplete(_ name: String) -> Bool {
        let fm = FileManager.default
        let folder = cacheRootURL.appendingPathComponent(name)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: folder.path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        for component in requiredModelComponents {
            let url = folder.appendingPathComponent(component)
            var compIsDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &compIsDir), compIsDir.boolValue,
                  let contents = try? fm.contentsOfDirectory(atPath: url.path), !contents.isEmpty
            else {
                return false
            }
        }
        return true
    }

    // MARK: - Model lifecycle

    /// Delete a cached model from disk to free space. Refuses to delete the currently-loaded model
    /// (the user must switch to a different one first). Updates `downloadedModels` on success.
    func removeModel(_ name: String) async throws {
        if loadedModelName == name || modelName == name {
            // Defensive — UI should hide the delete affordance on the active model.
            return
        }
        let folder = Self.cacheRootURL.appendingPathComponent(name)
        try FileManager.default.removeItem(at: folder)
        downloadedModels.remove(name)
    }

    /// Wipe every cached model and reset back to a fresh state. Tearing down the active model too,
    /// so the next Live screen has to re-download. Used by Settings → Erase downloaded models.
    func removeAllModels() async throws {
        loadTask?.cancel()
        loadTask = nil
        whisperBox = nil
        loadedModelName = nil
        loadState = .idle
        let fm = FileManager.default
        if fm.fileExists(atPath: Self.cacheRootURL.path) {
            try fm.removeItem(at: Self.cacheRootURL)
        }
        downloadedModels = []
    }

    /// Switch to a different Whisper model. If the model isn't on disk yet, this kicks off a
    /// download (or surfaces `.waitingForWifi` if we're on cellular and `allowCellular` is false).
    /// Call from Settings when the user picks a new model. Calling with the already-loaded model
    /// is a no-op.
    func setModel(_ newName: String, allowCellular: Bool = false) async throws {
        guard newName != modelName || loadedModelName != newName else {
            return
        }
        // Cancel any in-flight load, drop the current model, then load the new one.
        loadTask?.cancel()
        loadTask = nil
        whisperBox = nil
        loadedModelName = nil
        modelName = newName
        loadState = .idle
        try await loadModel(allowCellular: allowCellular)
    }

    /// Loads (and downloads, on first run) the Whisper model. Idempotent — calling again while
    /// a load is in flight just awaits the existing task.
    ///
    /// Wi-Fi rule: if the model isn't already on disk and the device is on cellular, the call
    /// returns with `loadState = .waitingForWifi`. Pass `allowCellular: true` to override.
    func loadModel(allowCellular: Bool = false) async throws {
        // Already loaded the model we want? Nothing to do.
        if case .ready = loadState, loadedModelName == modelName { return }
        if let existing = loadTask {
            try await existing.value
            return
        }

        // Re-scan disk every load. The in-memory `downloadedModels` from init can go stale
        // — model deleted in Settings, cache cleared, etc. Cheap (one directory listing).
        self.downloadedModels = Self.scanCachedModels()

        // Wi-Fi gate: if we'd need to download (not already cached) and we're on cellular,
        // surface the wait state instead of burning the user's data plan.
        // NOTE: completeness, not mere folder-existence — a partially-downloaded model folder
        // must be re-downloaded to repair it, or `WhisperKit(...)` fails with "Model file not
        // found". This was the App Review rejection.
        let alreadyOnDisk = Self.isModelComplete(modelName)
        if !alreadyOnDisk && !allowCellular && !network.isOnWifi {
            loadState = .waitingForWifi
            return
        }

        let target = modelName
        let cachedFolder = Self.cacheRootURL.appendingPathComponent(target)
        let task = Task { [self] in
            do {
                // Path 1: model already on disk → SKIP `WhisperKit.download` entirely. The
                // previous behavior called download() on every load, which (a) flashed
                // "Downloading… 0%" in the UI and (b) made WhisperKit walk the on-disk
                // snapshot every time. Going straight to .compiling is faster and stops
                // the perceived "downloading too often" issue users reported on TestFlight.
                //
                // Path 2: not on disk → call download with progress so ModelDownloadingView
                // can show real bytes pulled from Hugging Face.
                let folder: URL
                if alreadyOnDisk {
                    log.info("Model \(target, privacy: .public) cached at \(cachedFolder.path, privacy: .public) — skipping download")
                    folder = cachedFolder
                } else {
                    self.loadState = .loading(progress: 0)
                    folder = try await Self.downloadModel(variant: target) { [weak self] frac in
                        Task { @MainActor [weak self] in
                            self?.loadState = .loading(progress: frac)
                        }
                    }
                }

                // Next step (prewarm + load → Core ML compile for the ANE) has no progress
                // callback and can be slow for large models on first launch. After the
                // first compile, Core ML caches the compiled graph and this is fast.
                self.loadState = .compiling

                let kit = try await WhisperKit(
                    WhisperKitConfig(
                        model: target,
                        modelFolder: folder.path,
                        prewarm: true,
                        load: true,
                        download: false
                    )
                )
                // The download succeeded — the model is now on disk regardless of whether the
                // user has since switched away.
                self.downloadedModels.insert(target)
                // Only adopt the result if we still want this model (user may have switched again).
                if self.modelName == target {
                    self.whisperBox = KitBox(kit)
                    self.loadedModelName = target
                    self.loadState = .ready
                }
            } catch {
                // If we trusted an on-disk model and it still failed to load, the cache is
                // corrupt/incomplete in a way our component check didn't catch. Remove it so the
                // next attempt re-downloads a clean copy — otherwise the user is stuck forever.
                if alreadyOnDisk {
                    try? FileManager.default.removeItem(at: cachedFolder)
                    self.downloadedModels.remove(target)
                }
                self.loadState = .failed(message: String(describing: error))
                throw error
            }
        }
        self.loadTask = task
        defer { self.loadTask = nil }
        try await task.value
    }

    /// Bridge to `WhisperKit.download(...)` from a nonisolated context. Keeps the non-Sendable
    /// `(Progress) -> Void` closure entirely off MainActor so Swift 6 strict concurrency is happy.
    nonisolated private static func downloadModel(
        variant: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        try await WhisperKit.download(
            variant: variant,
            downloadBase: nil,
            useBackgroundSession: false,
            from: "argmaxinc/whisperkit-coreml"
        ) { p in
            progress(p.fractionCompleted)
        }
    }

    /// Transcribe an audio file (WAV / 16 kHz mono Float32 expected, but WhisperKit handles others).
    /// Used by tests and any future "transcribe a recorded file" flow.
    /// Pass `translate: true` to run Whisper in `.translate` mode — any source language is
    /// output as English. Otherwise captions stay in the spoken language.
    func transcribe(audioFile url: URL, language: String? = nil, translate: Bool = false) async throws -> String {
        if whisperBox == nil { try await loadModel() }
        guard let box = whisperBox else { throw TranscriptionError.modelNotLoaded }
        let path = url.path
        let opts = decodeOptions(language: language, translate: translate)
        let results = try await Task.detached {
            try await box.kit.transcribe(audioPath: path, decodeOptions: opts)
        }.value
        return results.map(\.text).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Transcribe a contiguous block of float samples (16 kHz mono). Used by the live-stream
    /// pipeline once we accumulate enough audio for a sliding window.
    /// Pass a Whisper language code (e.g. "en", "es") to pin the language; nil = auto-detect.
    /// Pass `translate: true` for any-source → English output (Whisper's `.translate` task).
    func transcribe(samples: [Float], language: String? = nil, translate: Bool = false) async throws -> String {
        if whisperBox == nil { try await loadModel() }
        guard let box = whisperBox else { throw TranscriptionError.modelNotLoaded }
        let opts = decodeOptions(language: language, translate: translate)
        let results = try await Task.detached {
            try await box.kit.transcribe(audioArray: samples, decodeOptions: opts)
        }.value
        return results.map(\.text).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Build the WhisperKit decoding options. Pinning a language is faster + more accurate;
    /// auto-detect is more flexible but adds a language-detection pass each window. Setting
    /// `translate: true` switches the task to `.translate`, which composes with both modes —
    /// `detectLanguage` runs first, then translation happens at decode time.
    nonisolated private func decodeOptions(language: String?, translate: Bool) -> DecodingOptions {
        var opts = DecodingOptions()
        if let language {
            opts.language = language
            opts.detectLanguage = false
        } else {
            opts.detectLanguage = true
        }
        opts.task = translate ? .translate : .transcribe
        // Disable KV-cache prefill across windows. Known issue in WhisperKit ≤ 0.18: the Turbo
        // variants of Large v3 hang on the second transcribe call when the cache is reused.
        // Small/Base transcribe fine with prefill on, but the perf savings are modest (~20-50 ms
        // per window), so we trade it for cross-model reliability.
        opts.usePrefillCache = false
        opts.usePrefillPrompt = false
        return opts
    }
}
