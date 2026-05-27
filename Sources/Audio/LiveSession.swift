import Foundation
import Observation
import OSLog
import SwiftData

private let log = Logger(subsystem: "com.briankemler.LiveTranscribe", category: "LiveSession")

/// One running live transcription pipeline. Owned by a `LiveView`, created when the screen
/// appears and torn down when it goes away.
///
/// Pipeline:
///   AudioCaptureService → 5 s sliding window → TranscriptionService → SpeakerHeuristic → lines
///
/// We accumulate ~5 s of audio, transcribe the whole window, diff against the last transcript to
/// find the new tail, and emit that as a `TranscriptLine`. WhisperKit's streaming demos do
/// the same trick — it's the simplest stable approach without modifying the model.
@MainActor
@Observable
final class LiveSession {

    // MARK: - Observed state

    /// All finalized lines, in order.
    private(set) var lines: [TranscriptLine] = []

    /// In-progress line currently being typed out — has the blinking caret.
    /// Nil before the first transcript chunk lands.
    private(set) var currentLine: TranscriptLine?

    /// 0...1 RMS for the waveform UI, smoothed.
    var audioLevel: Float { audio.audioLevel }

    /// Whether the underlying capture is paused.
    private(set) var isPaused: Bool = false

    /// Wall-clock start of this session. Drives the live elapsed timer in the LiveView top-bar.
    let startedAt: Date = Date()
    /// Stable UUID used to look this conversation up via `Route.summary(...)` after the
    /// session ends. Mirrored to the SwiftData record's `id`.
    let conversationID: UUID = UUID()

    /// Whether the transcription model is still loading (download + warmup).
    var isLoadingModel: Bool {
        if case .ready = transcription.loadState { return false }
        return true
    }

    /// Surfaced error message if the pipeline has failed; nil while healthy.
    private(set) var error: String?

    // MARK: - Microphones (multi-channel input)

    /// Number of physical mics detected on the active input. 1 = built-in / single-channel
    /// (fall back to the pause-based `SpeakerHeuristic`); ≥ 2 = a multi-channel interface where
    /// each channel is a mic and we attribute lines + light up pills by channel.
    private(set) var micCount: Int = 1

    /// Smoothed 0...1 input level per mic (index = channel). Drives the mic pills.
    private(set) var micLevels: [Float] = []

    /// Index of the mic currently loudest above the noise floor, or nil when the room is quiet.
    /// Used both for the active-pill highlight and for attributing the in-progress line.
    private(set) var activeMic: Int?

    /// True when we should show mic pills + use mic-based attribution instead of the heuristic.
    var usesMicDiarization: Bool { micCount >= 2 }

    /// Diagnostics for the group header: the active input's name, whether it's an external device,
    /// and the max channels it offers. Used to explain "external mic connected but it's sending a
    /// mixed signal" when a device pre-mixes its mics (e.g. a wireless lav receiver in mono mode).
    private(set) var inputName: String = ""
    private(set) var inputIsExternal: Bool = false
    private(set) var maxInputChannels: Int = 1

    // MARK: - Debug telemetry (visible in UI)

    /// Seconds of audio accumulated so far. Climbs as the mic feeds the pipeline.
    private(set) var bufferSeconds: Double = 0
    /// Number of transcription passes that have completed.
    private(set) var transcribePasses: Int = 0
    /// Latest raw transcript from the most recent window (for debugging — UI shows the tailed version).
    private(set) var lastRawTranscript: String = ""
    /// Number of audio chunks received from the mic. Climbs while the tap fires.
    private(set) var chunksReceived: Int = 0

    // MARK: - Dependencies

    let mode: LiveMode
    let transcription: TranscriptionService
    let audio: AudioCaptureService
    /// Per-session sound classifier. Listens on the same tap as Whisper. `lastDetection` is
    /// what LiveView watches to push `Route.alert(detection)`.
    let soundRecognition: SoundRecognitionService

    /// Whisper language code currently used for transcription. nil = auto-detect.
    /// Updated live by the view layer when the user picks a language in Settings.
    var language: String? = nil
    /// When true, the transcribe loop sets WhisperKit's task to `.translate` — any source
    /// language is output as English. False (default) keeps captions in the spoken language.
    /// Picked up on the next sliding-window transcribe call, so mid-session toggling works.
    var translateToEnglish: Bool = false
    /// Master enable for the sound recognizer. When false, `start()` skips booting the
    /// `SNAudioStreamAnalyzer` entirely. Toggling at runtime is supported — see the
    /// `didSet` hook.
    var soundRecognitionEnabled: Bool = true {
        didSet {
            guard oldValue != soundRecognitionEnabled else { return }
            if soundRecognitionEnabled {
                // Start the recognizer if audio is already running.
                if audio.isRecording {
                    soundRecognition.start(format: audio.inputFormat, armed: armedSounds)
                }
            } else {
                soundRecognition.stop()
            }
        }
    }
    /// Classifier IDs the sound recognizer should alert on. Updated live by the view layer
    /// when the user toggles a chip in Settings → Sound recognition. Build-16: non-urgent
    /// sounds no longer have a parallel armed set — `SoundRecognitionService` auto-arms
    /// every ID in `SoundCatalog.allNonUrgentIDs` at start.
    var armedSounds: Set<String> = SoundCatalog.defaultArmedIDs {
        didSet { soundRecognition.updateArmed(armedSounds) }
    }

    private var heuristic: SpeakerHeuristic
    private var pipelineTask: Task<Void, Never>?
    /// SwiftData write target. Optional so previews / tests can run without one; when nil,
    /// the session works but doesn't persist.
    private let modelContext: ModelContext?
    /// The persisted record for this session. Created on `start()` once we have audio
    /// permission; updated as lines and detections land. Nil if `modelContext` is nil.
    private var record: ConversationRecord?
    /// `lastDetection.detectedAt` of the most recent detection we wrote to SwiftData, so
    /// `recordDetectionIfNeeded` doesn't double-write the same fire.
    private var lastPersistedDetectionAt: Date?
    /// Audio timing for `currentLine`, captured at the moment it became current. We persist
    /// the previous line with these values when it gets promoted off the live slot.
    private var currentLineAudioStart: TimeInterval = 0
    private var currentLineAudioEnd: TimeInterval = 0

    // Sliding-window state
    private var buffer: [Float] = []
    private let sampleRate: Double = 16_000
    /// Sliding-window size for each Whisper pass. Smaller = lower latency, less context, slightly
    /// lower accuracy on long sentences. 3 s is the sweet spot for casual conversation on A18 Pro.
    private let windowSeconds: Double = 3.0
    /// How often we re-run Whisper. Smaller = lines appear sooner but more CPU/battery.
    private let strideSeconds: Double = 1.0
    private var lastTranscriptText: String = ""
    private var lastEmissionTime: TimeInterval = 0
    /// Wall-clock host-time of the last *non-empty* emission. Used to compute the silence gap
    /// before a new line — that gap is what drives the group-mode speaker rotation heuristic.
    private var lastNonEmptyEmissionTime: TimeInterval = 0
    /// Wall-clock `Date` of the last finalized line. Drives the captions-screen silence pill
    /// (rev-2). Distinct from `lastNonEmptyEmissionTime` (audio host time) so the UI can
    /// compute "seconds since last speech" without round-tripping through host-time math.
    /// Updated to `Date()` at the same call site as `lastNonEmptyEmissionTime`.
    private(set) var lastNonEmptyEmissionWallClock: Date?

    /// Seconds since the last finalized non-empty caption line, or 0 if nothing has been
    /// transcribed yet. Captions screen polls this via a 1-Hz timer to show the silence pill
    /// once silence ≥ 5 s (per `Design/CAPTIONS_HANDOFF.md` §"Silence").
    var silenceSeconds: TimeInterval {
        guard let last = lastNonEmptyEmissionWallClock else { return 0 }
        return max(0, Date().timeIntervalSince(last))
    }

    // MARK: - Init

    init(
        mode: LiveMode,
        transcription: TranscriptionService,
        audio: AudioCaptureService = AudioCaptureService(),
        soundRecognition: SoundRecognitionService = SoundRecognitionService(),
        modelContext: ModelContext? = nil
    ) {
        self.mode = mode
        self.transcription = transcription
        self.audio = audio
        self.soundRecognition = soundRecognition
        self.modelContext = modelContext
        self.heuristic = SpeakerHeuristic(mode: mode)
    }

    // MARK: - Lifecycle

    /// Boots permission → model load → mic stream → transcribe loop. Long-running; cancel via stop().
    func start() async {
        do {
            // 1. Mic permission
            if audio.permission == .unknown {
                _ = await audio.requestPermission()
            }
            guard audio.permission == .granted else {
                error = "Microphone permission was denied. Open Settings to grant access."
                return
            }

            // 2. Model load (no-op if AppState already kicked it off)
            try await transcription.loadModel()

            // 3. Wire sound-recognition fan-out *before* starting the engine so we don't miss
            //    any tap callbacks. Captures the service nonisolated `analyze` so the audio
            //    thread can call it without hopping to MainActor. Until `soundRecognition.start`
            //    runs, `analyze` is a cheap no-op (the analyzer slot is nil).
            let recognizer = soundRecognition
            audio.onRawBuffer = { buffer, time in
                recognizer.analyze(buffer: buffer, at: time)
            }

            // 4. Create the SwiftData record for this conversation so lines / detections
            //    have a parent to attach to as they arrive.
            createConversationRecord()

            // 5. Start audio + run the transcribe loop
            let stream = try audio.start()

            // Pick up how many mics the active input exposes (≥ 2 ⇒ multi-mic group screen).
            micCount = audio.micCount
            inputName = audio.inputName
            inputIsExternal = audio.inputIsExternal
            maxInputChannels = audio.maxInputChannels
            if micCount >= 2 { micLevels = [Float](repeating: 0, count: micCount) }

            // 6. Now that the audio session is live, the inputNode's format is final. Boot the
            //    SNAudioStreamAnalyzer with it — but only if the master enable in Settings is on.
            //    When off, the fan-out hook is still installed but `analyze` is a no-op since
            //    the analyzer slot stays nil.
            if soundRecognitionEnabled {
                soundRecognition.start(format: audio.inputFormat, armed: armedSounds)
            }
            pipelineTask = Task { [weak self] in
                await self?.runPipeline(stream: stream)
            }
            await pipelineTask?.value
        } catch {
            self.error = String(describing: error)
            stop()
        }
    }

    func pause() {
        guard !isPaused else { return }
        isPaused = true
        audio.pause()
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        try? audio.resume()
    }

    func stop() {
        pipelineTask?.cancel()
        pipelineTask = nil
#if DEBUG
        demoMicTask?.cancel()
        demoMicTask = nil
#endif
        soundRecognition.stop()
        audio.onRawBuffer = nil
        audio.stop()
        // Promote any in-progress line to the finalized list, and persist it with its
        // captured timing window.
        if let last = currentLine {
            lines.append(last)
            persistLine(last, audioStart: currentLineAudioStart, audioEnd: currentLineAudioEnd)
            currentLine = nil
        }
        finalizeConversationRecord()
    }

    /// Stop the session and return the SwiftData conversation id so the view can navigate
    /// to its `Summary` (`Route.summary(id)`). Rev-2 captions pause button maps to this.
    /// Returns nil when no `modelContext` was supplied (e.g. preview / tests).
    func endAndSave() -> UUID? {
        stop()
        return record?.id
    }

    /// Tear down the session and delete its `ConversationRecord` from SwiftData. Used by
    /// the rev-2 captions back chevron when the user wants to abandon the session without
    /// saving (e.g. they started in the wrong mode). The cascade-delete relationship on
    /// `ConversationRecord` cleans up any persisted lines + detections.
    func discardAndExit() {
        stop()
        guard let ctx = modelContext, let r = record else { return }
        ctx.delete(r)
        try? ctx.save()
        record = nil
    }

    /// Toggle the active conversation's `isStarred` flag. Build-14: replaces the prior
    /// `starMostRecentLine()`. Whole-conversation starring is what the captions screen's
    /// star button represents — bookmarking the transcript for later, surfaced via Settings
    /// → Transcripts and the History "Starred" filter. Returns the new value so the view
    /// can flip the icon between filled (saved) and hollow (not saved).
    @discardableResult
    func starConversation() -> Bool {
        guard let ctx = modelContext, let r = record else { return false }
        r.isStarred.toggle()
        try? ctx.save()
        return r.isStarred
    }

#if DEBUG
    /// Screenshot/demo seeding. Populates the caption slots with scripted lines and skips the
    /// real audio + model pipeline entirely. Triggered only by the `--demo-captions` launch
    /// arg on a Debug build (see `CaptionsView.task`); the whole method is compiled out of
    /// Release, so the App Store binary is unaffected. This exists because the iOS Simulator
    /// on Apple Silicon can't capture mic input, so a populated captions screen — the app's
    /// hero shot — can't otherwise be screenshotted without a physical device.
    func seedDemoCaptions(history: [TranscriptLine], current: TranscriptLine) {
        lines = history
        currentLine = current
        // Suppress the silence pill: pretend the last line landed just now.
        lastNonEmptyEmissionWallClock = Date()
    }

    /// Screenshot/demo seeding for the multi-mic group screen. Sets up `count` mics with a
    /// transcript attributed to them and rotates the "active" mic on a timer so the pills can be
    /// seen lighting up. Skips the real audio pipeline (the Simulator has no multi-channel input).
    /// Triggered only by `--demo-mics N` on a Debug build; compiled out of Release.
    func seedDemoMics(count: Int) {
        let n = max(2, count)
        micCount = n
        activeMic = 0
        micLevels = (0..<n).map { $0 == 0 ? 0.82 : 0.06 }
        lastNonEmptyEmissionWallClock = Date()

        // A short scripted exchange, each line tagged to the mic that "said" it.
        let script = [
            "Wait, you actually finished the marathon?",
            "Four hours twelve. My knees still hate me.",
            "Okay but the real question is what's for dessert.",
        ]
        lines = script.enumerated().dropLast().map { i, text in
            TranscriptLine(speaker: .mic((i % n) + 1), text: text)
        }
        let lastIdx = script.count - 1
        currentLine = TranscriptLine(speaker: .mic((lastIdx % n) + 1), text: script[lastIdx])
        activeMic = lastIdx % n

        // Gently rotate the active mic so the "light up when speaking" behavior is visible live.
        demoMicTask = Task { @MainActor [weak self] in
            var i = lastIdx % n
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                guard !Task.isCancelled, let self else { return }
                i = (i + 1) % n
                self.activeMic = i
                self.micLevels = (0..<n).map { $0 == i ? 0.82 : 0.06 }
            }
        }
    }

    private var demoMicTask: Task<Void, Never>?
#endif

    // MARK: - Persistence helpers

    /// Insert the empty `ConversationRecord` for this session so downstream writes can
    /// attach lines + detections to it. Safe to call when no `modelContext` is configured.
    private func createConversationRecord() {
        guard let ctx = modelContext, record == nil else { return }
        let r = ConversationRecord(
            id: conversationID,
            modeRaw: mode == .group ? "group" : "oneToOne",
            startedAt: startedAt
        )
        ctx.insert(r)
        record = r
        try? ctx.save()
    }

    /// Set `endedAt` and flush. Cheap if the session was never started or has no context.
    private func finalizeConversationRecord() {
        guard let ctx = modelContext, let r = record else { return }
        r.endedAt = Date()
        try? ctx.save()
    }

    /// Append a `TranscriptLineRecord` mirroring `line` to the current conversation. Idempotent
    /// when called with the same `TranscriptLine.id` — checks the record's existing line ids.
    fileprivate func persistLine(_ line: TranscriptLine, audioStart: TimeInterval, audioEnd: TimeInterval) {
        guard let ctx = modelContext, let r = record else { return }
        // The line's stable id is its dedupe key — same UUID = same persisted record.
        if r.lines.contains(where: { $0.id == line.id }) { return }
        let rec = TranscriptLineRecord(
            id: line.id,
            speakerId: line.speaker.id,
            speakerDisplayName: line.speaker.displayName,
            speakerInitial: line.speaker.initial,
            speakerColorRoleRaw: line.speaker.colorRole.raw,
            text: line.text,
            audioStart: audioStart,
            audioEnd: audioEnd
        )
        rec.conversation = r
        ctx.insert(rec)
        try? ctx.save()
    }

    /// Called by `LiveView` whenever it observes a new `SoundRecognitionService.lastDetection`
    /// and pushes the alert. We dedupe by `detectedAt` so we don't write twice on the same fire.
    func recordDetection(_ detection: SoundDetection) {
        guard let ctx = modelContext, let r = record else { return }
        if lastPersistedDetectionAt == detection.detectedAt { return }
        lastPersistedDetectionAt = detection.detectedAt
        let rec = SoundDetectionRecord(
            classifierID: detection.sound.classifierID,
            label: detection.sound.label,
            icon: detection.sound.icon,
            confidence: detection.confidence,
            detectedAt: detection.detectedAt
        )
        rec.conversation = r
        r.hadUrgentDetection = true
        ctx.insert(rec)
        try? ctx.save()
    }

    // MARK: - Pipeline

    private func runPipeline(stream: AsyncStream<AudioCaptureService.AudioChunk>) async {
        log.info("pipeline starting — mode \(String(describing: self.mode))")
        for await chunk in stream {
            if Task.isCancelled { break }
            if isPaused { continue }

            buffer.append(contentsOf: chunk.samples)
            chunksReceived += 1
            bufferSeconds = Double(buffer.count) / sampleRate

            // Multi-mic: smooth the per-channel levels for the pills and track the active mic.
            // We hold the last active mic through brief gaps (the silence pill covers real silence).
            if micCount >= 2, chunk.channelRMS.count == micCount {
                if micLevels.count != micCount { micLevels = chunk.channelRMS }
                else { for i in 0..<micCount { micLevels[i] += (chunk.channelRMS[i] - micLevels[i]) * 0.4 } }
                if chunk.activeChannel >= 0 { activeMic = chunk.activeChannel }
            }

            if chunksReceived % 10 == 1 {
                log.debug("chunk \(self.chunksReceived) — rms=\(chunk.rms, format: .fixed(precision: 3)) bufSec=\(self.bufferSeconds, format: .fixed(precision: 2))")
            }

            // Decide whether to run a transcription pass: every ~strideSeconds of new audio.
            let totalSeconds = Double(buffer.count) / sampleRate
            if totalSeconds < windowSeconds { continue }

            let now = chunk.timestamp
            if now - lastEmissionTime < strideSeconds && !lastTranscriptText.isEmpty { continue }
            lastEmissionTime = now

            // Transcribe the most recent windowSeconds worth.
            let windowSamples = Int(windowSeconds * sampleRate)
            let start = max(0, buffer.count - windowSamples)
            let window = Array(buffer[start..<buffer.count])

            log.info("transcribing window \(window.count) samples (~\(Double(window.count) / self.sampleRate, format: .fixed(precision: 1))s) lang=\(self.language ?? "auto")")
            let transcript: String
            do {
                transcript = try await transcription.transcribe(samples: window, language: language, translate: translateToEnglish)
            } catch {
                log.error("transcribe error: \(String(describing: error))")
                continue
            }
            transcribePasses += 1
            lastRawTranscript = transcript
            log.info("transcribe pass \(self.transcribePasses) → '\(transcript)'")

            // Diff the new transcript against the last one to find the new tail. WhisperKit
            // returns the full window, so most of it overlaps with the previous emission.
            let newText = newTail(of: transcript, vs: lastTranscriptText)
            lastTranscriptText = transcript
            guard !newText.isEmpty else { continue }

            // Compute silence as wall-clock time since the last *non-empty* emission. That's the
            // signal the speaker-rotation heuristic uses: long gaps mean someone else probably
            // took the floor. First emission gets 0 (no rotation possible).
            let silenceMs: Int
            if lastNonEmptyEmissionTime > 0 {
                silenceMs = max(0, Int((now - lastNonEmptyEmissionTime) * 1000))
            } else {
                silenceMs = 0
            }
            lastNonEmptyEmissionTime = now
            lastNonEmptyEmissionWallClock = Date()

            let partial = PartialTranscript(
                text: newText,
                isFinal: true,
                audioStart: now - strideSeconds,
                audioEnd: now,
                silenceBeforeMs: silenceMs
            )
            // Attribution: with a multi-channel interface, tag the line with the mic that was
            // loudest (real per-mic diarization). Otherwise fall back to the pause heuristic.
            let line: TranscriptLine
            if micCount >= 2, let mic = activeMic {
                line = TranscriptLine(speaker: .mic(mic + 1), text: partial.text)
            } else {
                line = heuristic.line(for: partial)
            }

            // Promote the in-progress line and start a new one.
            if let prev = currentLine {
                lines.append(prev)
                persistLine(prev, audioStart: currentLineAudioStart, audioEnd: currentLineAudioEnd)
            }
            currentLine = line
            currentLineAudioStart = partial.audioStart
            currentLineAudioEnd = partial.audioEnd

            // Bound the buffer so we don't grow forever — keep last 30 s.
            let keep = Int(30 * sampleRate)
            if buffer.count > keep {
                buffer.removeFirst(buffer.count - keep)
            }
        }
    }

    /// Naive longest-common-prefix tail extractor. Whisper's overlapping windows produce
    /// `"the quick brown"` then `"the quick brown fox"` — we want `"fox"`.
    private func newTail(of new: String, vs old: String) -> String {
        guard !old.isEmpty else { return new.trimmingCharacters(in: .whitespaces) }
        if new.hasPrefix(old) {
            return String(new.dropFirst(old.count)).trimmingCharacters(in: .whitespaces)
        }
        // Fallback: find longest common suffix-of-old / prefix-of-new and trim.
        let oldChars = Array(old)
        let newChars = Array(new)
        var overlap = 0
        let maxCheck = min(oldChars.count, newChars.count, 128)
        for n in stride(from: maxCheck, through: 1, by: -1) where oldChars.suffix(n) == newChars.prefix(n) {
            overlap = n
            break
        }
        return String(newChars.dropFirst(overlap)).trimmingCharacters(in: .whitespaces)
    }
}
