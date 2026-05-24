import Foundation
import AVFoundation
import SoundAnalysis
import Observation
import OSLog

private let log = Logger(subsystem: "com.briankemler.LiveTranscribe", category: "SoundRecognition")

/// Listens for environmental sounds using Apple's built-in
/// `SNClassifySoundRequest(classifierIdentifier: .version1)`. No external model — the
/// classifier ships with iOS, no download, no on-disk cost.
///
/// Build-14: routes detections by category. **Urgent** hits (smoke alarm, baby crying, …)
/// update `lastDetection` and the caller pushes `AlertView`. **Ambient/social** hits
/// (laughter, music, wind, …) update `lastAmbientDetection` which the captions screen
/// surfaces as a non-blocking margin tag. The classifier runs once and the same
/// `SNAudioStreamAnalyzer` feeds both routes — only the routing differs.
///
/// Per-label `debounceWindow` is applied within each category so a continuous smoke alarm
/// doesn't re-fire AlertView, and a steady music background doesn't redraw the margin tag
/// on every prediction window.
@MainActor
@Observable
final class SoundRecognitionService {

    /// Default confidence floor for an armed sound to fire. Tuned conservatively — Apple's
    /// version1 classifier emits ~0.9+ on clear smoke alarms and ~0.6-0.8 on noisier samples.
    static let defaultThreshold: Float = 0.7

    /// Per-label cooldown after a fire.
    static let debounceWindow: TimeInterval = 30

    /// Most-recent qualifying *urgent* detection. View watches via `@Observable` and pushes
    /// `Route.alert(detection)` on change.
    private(set) var lastDetection: SoundDetection?

    /// Most-recent qualifying *ambient/social* detection. Captions screen reads this to
    /// drive the right-margin tag.
    private(set) var lastAmbientDetection: SoundDetection?

    /// Nonisolated handle to the analyzer + observer.
    private let streamBox = StreamBox()

    init() {}

    /// Build the analyzer for a given input format. Stops the previous analyzer first.
    /// `armed` = urgent IDs the user has picked (up to `SoundCatalog.maxUrgent`). Non-urgent
    /// detection auto-arms every ID in `SoundCatalog.allNonUrgentIDs` — the user doesn't
    /// pick ambient sounds in build 16+.
    func start(format: AVAudioFormat, armed: Set<String>) {
        let armedAmbient = SoundCatalog.allNonUrgentIDs
        stop()
        do {
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            request.overlapFactor = 0.5

            let analyzer = SNAudioStreamAnalyzer(format: format)
            let stream = AnalysisStream(
                analyzer: analyzer,
                threshold: Self.defaultThreshold,
                debounce: Self.debounceWindow,
                armed: armed,
                armedAmbient: armedAmbient
            )
            try analyzer.add(request, withObserver: stream)
            stream.onUrgentDetection = { [weak self] detection in
                Task { @MainActor [weak self] in self?.lastDetection = detection }
            }
            stream.onAmbientDetection = { [weak self] detection in
                Task { @MainActor [weak self] in self?.lastAmbientDetection = detection }
            }
            streamBox.value = stream
            log.info("SoundRecognition started · sr=\(format.sampleRate) ch=\(format.channelCount) urgentArmed=\(armed.count) ambientArmed=\(armedAmbient.count)")

            // Telemetry: log unknown classifier IDs once per start.
            let known = Set(request.knownClassifications)
            for id in armed.union(armedAmbient) where !known.contains(id) {
                log.warning("Armed sound \"\(id)\" is not in SNClassifierIdentifier.version1.knownClassifications on this iOS — detection for it will never fire.")
            }
        } catch {
            log.error("Failed to start SoundAnalysis: \(String(describing: error))")
            streamBox.value = nil
        }
    }

    /// Update the urgent armed set without rebuilding the analyzer.
    func updateArmed(_ armed: Set<String>) {
        streamBox.value?.setArmed(armed)
    }

    // Build-16: removed `updateArmedAmbient` — non-urgent IDs are auto-armed at start.

    /// Feed one tap buffer into the classifier. Safe to call from the audio thread.
    nonisolated func analyze(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        streamBox.value?.analyze(buffer: buffer, at: time)
    }

    func stop() {
        streamBox.value?.tearDown()
        streamBox.value = nil
    }
}

// MARK: - Nonisolated analysis stream

/// Owns the `SNAudioStreamAnalyzer` + observer state. `@unchecked Sendable` because all
/// mutable state is guarded by a lock and the analyzer's API is internally thread-safe.
private final class AnalysisStream: NSObject, SNResultsObserving, @unchecked Sendable {
    private let analyzer: SNAudioStreamAnalyzer
    private let threshold: Float
    private let debounce: TimeInterval
    private let lock = NSLock()
    private var armed: Set<String>            // urgent
    private var armedAmbient: Set<String>     // social + ambient
    private var lastFiredAt: [String: Date] = [:]

    /// Fired on qualifying urgent detections. Owner hops to MainActor.
    var onUrgentDetection: (@Sendable (SoundDetection) -> Void)?
    /// Fired on qualifying ambient/social detections. Owner hops to MainActor.
    var onAmbientDetection: (@Sendable (SoundDetection) -> Void)?

    init(
        analyzer: SNAudioStreamAnalyzer,
        threshold: Float,
        debounce: TimeInterval,
        armed: Set<String>,
        armedAmbient: Set<String>
    ) {
        self.analyzer = analyzer
        self.threshold = threshold
        self.debounce = debounce
        self.armed = armed
        self.armedAmbient = armedAmbient
    }

    func setArmed(_ next: Set<String>) {
        lock.lock(); defer { lock.unlock() }
        armed = next
    }

    func setArmedAmbient(_ next: Set<String>) {
        lock.lock(); defer { lock.unlock() }
        armedAmbient = next
    }

    func analyze(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
    }

    func tearDown() {
        analyzer.removeAllRequests()
        onUrgentDetection = nil
        onAmbientDetection = nil
    }

    // MARK: SNResultsObserving

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classification = result as? SNClassificationResult else { return }
        // Snapshot state under lock so concurrent armed-set updates can't race with the
        // per-label cooldown check.
        lock.lock()
        let urgentNow = armed
        let ambientNow = armedAmbient
        var firedUrgent: (String, Float, Date)?
        var firedAmbient: (String, Float, Date)?

        // The classifier returns its top N classifications per result. Walk them looking
        // for the highest-ranked qualifying hit in each category — we want at most one
        // event per category per result, with urgent taking precedence over ambient.
        for c in classification.classifications {
            let id = c.identifier
            let confidence = Float(c.confidence)
            guard confidence >= threshold else { continue }
            let now = Date()
            if urgentNow.contains(id), firedUrgent == nil {
                if let last = lastFiredAt[id], now.timeIntervalSince(last) < debounce { continue }
                lastFiredAt[id] = now
                firedUrgent = (id, confidence, now)
            } else if ambientNow.contains(id), firedAmbient == nil {
                if let last = lastFiredAt[id], now.timeIntervalSince(last) < debounce { continue }
                lastFiredAt[id] = now
                firedAmbient = (id, confidence, now)
            }
            if firedUrgent != nil && firedAmbient != nil { break }
        }
        lock.unlock()

        if let f = firedUrgent, let sound = SoundCatalog.byID[f.0] {
            log.info("Urgent sound detected: \(f.0) confidence=\(f.1)")
            onUrgentDetection?(SoundDetection(sound: sound, confidence: f.1, detectedAt: f.2))
        }
        if let f = firedAmbient, let sound = SoundCatalog.byID[f.0] {
            log.info("Ambient sound detected: \(f.0) confidence=\(f.1)")
            onAmbientDetection?(SoundDetection(sound: sound, confidence: f.1, detectedAt: f.2))
        }
    }

    func request(_ request: SNRequest, didFailWithError error: any Error) {
        log.error("SoundAnalysis failure: \(String(describing: error))")
    }

    func requestDidComplete(_ request: SNRequest) {}
}

/// Small atomic box so a MainActor-set reference can be read from the audio thread.
private final class StreamBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: AnalysisStream?
    var value: AnalysisStream? {
        get { lock.lock(); defer { lock.unlock() }; return _value }
        set { lock.lock(); _value = newValue; lock.unlock() }
    }
}
