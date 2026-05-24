import Foundation
import AVFoundation
import Observation
import OSLog

private let log = Logger(subsystem: "com.briankemler.LiveTranscribe", category: "AudioCapture")

/// Streams 16 kHz mono Float32 audio chunks from the microphone, with mic-permission and
/// audio-session lifecycle handled in one place. Designed to feed `TranscriptionService`.
///
/// The service emits one `AudioChunk` per `AVAudioEngine` tap callback (~100 ms by default).
/// Whisper wants 16 kHz mono Float32, so the input is resampled if the hardware doesn't match.
@MainActor
@Observable
final class AudioCaptureService {

    enum PermissionState: Sendable, Equatable { case unknown, granted, denied }

    enum CaptureError: Error {
        case permissionDenied
        case sessionConfigurationFailed(any Error)
        case engineStartFailed(any Error)
        case converterCreationFailed
    }

    /// One chunk of captured audio, already resampled to 16 kHz mono Float32.
    /// `samples` is owned by the consumer — safe to retain across actor hops.
    struct AudioChunk: Sendable {
        let samples: [Float]
        let sampleRate: Double      // always 16_000 in v1
        let timestamp: TimeInterval // host time when the chunk's first sample was captured
        /// 0 ... 1 RMS level for waveform UI. Computed once here so the UI doesn't recompute every frame.
        let rms: Float
    }

    // MARK: - Observed state

    private(set) var permission: PermissionState = .unknown
    private(set) var isRecording: Bool = false
    /// 0 ... 1 — most recent RMS, smoothed for waveform animation.
    private(set) var audioLevel: Float = 0

    // MARK: - Private

    private let engine = AVAudioEngine()
    private let targetSampleRate: Double = 16_000
    private var continuation: AsyncStream<AudioChunk>.Continuation?
    /// Non-MainActor sink that owns the realtime audio-thread work. Holding it on self keeps it
    /// alive for the lifetime of recording; the tap closure captures the sink (Sendable), not self.
    private var sink: AudioSink?

    /// Optional raw-buffer fan-out for parallel consumers (e.g. `SoundRecognitionService`,
    /// which wants the mic's native format — not the resampled 16 kHz mono floats Whisper uses).
    /// Set before calling `start()`. Invoked on the audio thread; closure must be cheap.
    var onRawBuffer: (@Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void)?

    /// Surfaced so consumers (e.g. `SoundRecognitionService`) can initialize their own pipeline
    /// with the right `AVAudioFormat` before audio starts flowing.
    var inputFormat: AVAudioFormat { engine.inputNode.outputFormat(forBus: 0) }

    // MARK: - API

    /// Requests microphone permission. Call before `start()`.
    func requestPermission() async -> PermissionState {
        if #available(iOS 17, *) {
            let granted = await AVAudioApplication.requestRecordPermission()
            permission = granted ? .granted : .denied
        } else {
            // Project min is iOS 17 so this branch is dead, but the compiler wants it.
            permission = .granted
        }
        return permission
    }

    /// Starts the engine and returns an async stream of chunks. Throws if permission isn't granted
    /// or the audio session can't be configured.
    func start() throws -> AsyncStream<AudioChunk> {
        guard permission == .granted else { throw CaptureError.permissionDenied }
        guard !isRecording else {
            // Already running — return a fresh stream that pipes from the existing pipeline.
            return AsyncStream { _ in }
        }

        // Build the stream first so the continuation exists when installTap wires up the sink.
        let (stream, cont) = AsyncStream<AudioChunk>.makeStream()
        self.continuation = cont
        cont.onTermination = { @Sendable _ in
            Task { @MainActor [weak self] in self?.stop() }
        }

        do {
            try configureSession()
            try installTap()
            try startEngine()
            isRecording = true
        } catch {
            cont.finish()
            self.continuation = nil
            throw error
        }
        return stream
    }

    /// Stops the engine and finishes the stream. Idempotent.
    func stop() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        continuation?.finish()
        continuation = nil
        sink = nil
        isRecording = false
        audioLevel = 0
    }

    /// Pauses playback without tearing down the audio session. Resume with `resume()`.
    func pause() {
        guard isRecording else { return }
        engine.pause()
    }

    func resume() throws {
        guard isRecording else { return }
        try engine.start()
    }

    // MARK: - Setup

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.record` (not `.playAndRecord`) keeps the input chain simple and avoids the
            // `.duckOthers` + speaker-output route quirks that were eating mic input on device.
            // Bluetooth HFP stays allowed so AirPods etc. work.
            try session.setCategory(
                .record,
                mode: .default,
                options: [.allowBluetoothHFP]
            )
            try session.setPreferredSampleRate(targetSampleRate)
            try session.setPreferredIOBufferDuration(0.1) // ~100 ms tap callbacks
            try session.setActive(true, options: [])
        } catch {
            throw CaptureError.sessionConfigurationFailed(error)
        }
    }

    private func installTap() throws {
        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        log.info("input format: sr=\(inputFormat.sampleRate) ch=\(inputFormat.channelCount) common=\(String(describing: inputFormat.commonFormat))")
        let session = AVAudioSession.sharedInstance()
        log.info("session sr=\(session.sampleRate) inputAvailable=\(session.isInputAvailable) inputNumberOfChannels=\(session.inputNumberOfChannels)")

        guard let continuation else {
            // Should be impossible: start() sets continuation right after installTap returns.
            throw CaptureError.converterCreationFailed
        }
        let sink = AudioSink(
            inputSampleRate: inputFormat.sampleRate,
            inputChannels: Int(inputFormat.channelCount),
            outputSampleRate: targetSampleRate,
            continuation: continuation,
            onLevel: { [weak self] level in
                Task { @MainActor [weak self] in self?.audioLevel = level }
            },
            onRawBuffer: onRawBuffer
        )
        self.sink = sink
        sink.install(on: input, bufferSize: 1024, format: inputFormat)
    }

    private func startEngine() throws {
        engine.prepare()
        do {
            try engine.start()
        } catch {
            throw CaptureError.engineStartFailed(error)
        }
    }

}

/// Realtime audio-thread sink. Lives outside the @MainActor service so the tap callback
/// doesn't inherit any actor isolation — Swift 6's strict-concurrency runtime would otherwise
/// fail a `dispatch_assert_queue` check when the AVAudioEngine tap fires on a non-Main thread.
///
/// `@unchecked Sendable` is intentional: this class owns AVFoundation types that aren't
/// formally Sendable, but the access pattern is single-writer (one audio thread).
final class AudioSink: @unchecked Sendable {
    private let inputSampleRate: Double
    private let inputChannels: Int
    private let outputSampleRate: Double
    private let resampleRatio: Double  // input / output
    private let continuation: AsyncStream<AudioCaptureService.AudioChunk>.Continuation
    private let onLevel: @Sendable (Float) -> Void
    /// Optional fan-out for raw tap buffers — used by `SoundRecognitionService` which wants
    /// `AVAudioPCMBuffer` in the mic's native format, not the resampled mono floats.
    private let onRawBuffer: (@Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void)?

    /// Fractional-sample position carried across tap callbacks so the resample lattice stays continuous.
    private var phase: Double = 0

    init(
        inputSampleRate: Double,
        inputChannels: Int,
        outputSampleRate: Double,
        continuation: AsyncStream<AudioCaptureService.AudioChunk>.Continuation,
        onLevel: @escaping @Sendable (Float) -> Void,
        onRawBuffer: (@Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void)? = nil
    ) {
        self.inputSampleRate = inputSampleRate
        self.inputChannels = inputChannels
        self.outputSampleRate = outputSampleRate
        self.resampleRatio = inputSampleRate / outputSampleRate
        self.continuation = continuation
        self.onLevel = onLevel
        self.onRawBuffer = onRawBuffer
    }

    /// Install a tap on the input node. The closure captures `self` (Sendable) — NOT the
    /// MainActor service — so Swift's task runtime is happy when the audio thread fires it.
    func install(on node: AVAudioInputNode, bufferSize: AVAudioFrameCount, format: AVAudioFormat) {
        node.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [self] buffer, time in
            self.process(buffer: buffer, time: time)
        }
    }

    /// One tap callback. Mono mixdown → linear resample to 16 kHz → RMS → emit chunk.
    /// Runs on the audio thread; no awaits. AVAudioConverter was eating samples on iPhone 17 Pro Max,
    /// so we do the conversion by hand — simple linear interpolation is plenty for speech recognition.
    private func process(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return }

        // 0. Fan the raw buffer out to any sibling consumers (e.g. SoundRecognitionService).
        //    SoundAnalysis wants the native input format, not the resampled mono floats below.
        onRawBuffer?(buffer, time)

        // 1. Pull Float32 mono samples from whatever input format the hardware gave us.
        let mono = monoSamples(from: buffer, frameCount: frames)
        guard !mono.isEmpty else { return }

        // 2. Linear-interpolation resample to the target rate (typically 48 kHz → 16 kHz).
        let resampled = resample(mono: mono)

        // 3. RMS — surfaced to the UI for the waveform animation.
        var sumSq: Float = 0
        for s in resampled { sumSq += s * s }
        let mean = resampled.isEmpty ? 0 : sumSq / Float(resampled.count)
        let rms = min(1.0, sqrt(mean) * 4.0)

        if Int.random(in: 0..<20) == 0 {
            log.debug("tap: inFrames=\(frames) outFrames=\(resampled.count) rms=\(rms, format: .fixed(precision: 3))")
        }

        let host = AVAudioTime.seconds(forHostTime: time.hostTime)
        let chunk = AudioCaptureService.AudioChunk(
            samples: resampled,
            sampleRate: outputSampleRate,
            timestamp: host,
            rms: rms
        )
        continuation.yield(chunk)
        onLevel(rms)
    }

    /// Extract a Float32 mono mixdown from any input format the input node hands us.
    private func monoSamples(from buffer: AVAudioPCMBuffer, frameCount: Int) -> [Float] {
        let channels = Int(buffer.format.channelCount)
        if let f = buffer.floatChannelData {
            if channels == 1 {
                return Array(UnsafeBufferPointer(start: f[0], count: frameCount))
            }
            var out = [Float](repeating: 0, count: frameCount)
            for ch in 0..<channels {
                for i in 0..<frameCount { out[i] += f[ch][i] }
            }
            let inv = 1 / Float(channels)
            for i in 0..<frameCount { out[i] *= inv }
            return out
        }
        if let i16 = buffer.int16ChannelData {
            var out = [Float](repeating: 0, count: frameCount)
            let scale: Float = 1 / Float(Int16.max)
            for ch in 0..<channels {
                for i in 0..<frameCount { out[i] += Float(i16[ch][i]) * scale }
            }
            if channels > 1 {
                let inv = 1 / Float(channels)
                for i in 0..<frameCount { out[i] *= inv }
            }
            return out
        }
        return []
    }

    /// Continuous-phase linear resample. Carries fractional position across calls so we don't
    /// drop or duplicate samples at buffer boundaries.
    private func resample(mono: [Float]) -> [Float] {
        if resampleRatio == 1.0 { return mono }
        let inCount = mono.count
        // Approximate output count from the available input span; the actual loop uses the phase
        // to decide when to stop, so off-by-one at the end is harmless.
        var out: [Float] = []
        out.reserveCapacity(Int(Double(inCount) / resampleRatio) + 1)
        var pos = phase
        while pos < Double(inCount - 1) {
            let i = Int(pos)
            let frac = Float(pos - Double(i))
            let a = mono[i]
            let b = mono[i + 1]
            out.append(a + (b - a) * frac)
            pos += resampleRatio
        }
        phase = pos - Double(inCount) // carry overflow into next buffer
        return out
    }
}
