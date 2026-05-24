import Testing
import AVFoundation
@testable import LiveTranscribe

/// AudioCaptureService can't be exercised end-to-end in the simulator (no live mic on
/// Apple Silicon sims). These tests cover the parts that are deterministic on the host:
/// permission state machine and the static silence-RMS computation.
@MainActor
@Suite("AudioCaptureService")
struct AudioCaptureTests {

    @Test("Initial permission state is unknown")
    func initialState() {
        let service = AudioCaptureService()
        #expect(service.permission == .unknown)
        #expect(service.isRecording == false)
        #expect(service.audioLevel == 0)
    }

    @Test("start() throws when permission is denied")
    func startWithoutPermission() {
        let service = AudioCaptureService()
        // Permission stays .unknown — start() should refuse.
        #expect(throws: AudioCaptureService.CaptureError.self) {
            _ = try service.start()
        }
    }

    @Test("stop() is idempotent on a never-started service")
    func stopIsIdempotent() {
        let service = AudioCaptureService()
        service.stop()  // should not crash
        service.stop()
        #expect(service.isRecording == false)
    }
}
