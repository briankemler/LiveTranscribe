import Testing
import Foundation
@testable import LiveTranscribe

/// Integration tests for TranscriptionService. These talk to WhisperKit for real, which means:
///   - The first run downloads ~244 MB from Hugging Face (~30 s on Wi-Fi)
///   - Each transcription takes 1-3 s on simulator (CPU-only)
/// Marked `.serialized` so the model isn't loaded twice in parallel.
@MainActor
@Suite("TranscriptionService", .serialized)
struct TranscriptionServiceTests {

    @Test("Loads model + transcribes a TTS WAV fixture end-to-end", .timeLimit(.minutes(3)))
    func transcribesFixture() async throws {
        guard let url = Bundle(for: BundleAnchor.self).url(
            forResource: "quick_brown_fox",
            withExtension: "wav",
            subdirectory: "Fixtures"
        ) ?? Bundle(for: BundleAnchor.self).url(
            forResource: "quick_brown_fox",
            withExtension: "wav"
        ) else {
            Issue.record("Missing quick_brown_fox.wav fixture in test bundle")
            return
        }

        // Pin Small explicitly: this test proves the load + inference pipeline runs end-to-end, so
        // it shouldn't ride on the app's default-model choice (Base is less accurate and returns
        // empty on this synthetic `say`-generated fixture). Force past the Wi-Fi gate for CI.
        let service = TranscriptionService(network: NetworkMonitor(), modelName: "openai_whisper-small")
        try await service.loadModel(allowCellular: true)
        let text = try await service.transcribe(audioFile: url)

        // The fixture is `say`-generated TTS, which Whisper sometimes hallucinates on. The job of
        // this test is to prove the model loads + the inference pipeline runs end-to-end, not to
        // benchmark accuracy on synthetic speech. So: assert the service progressed to .ready and
        // we got SOMETHING back. Real-mic accuracy is verified manually on device.
        #expect(service.loadState == TranscriptionService.LoadState.ready)
        #expect(!text.isEmpty)
    }
}

/// Bundle anchor for `Bundle(for:)` lookups in Swift Testing (which doesn't have an `XCTestCase` self).
private final class BundleAnchor {}
