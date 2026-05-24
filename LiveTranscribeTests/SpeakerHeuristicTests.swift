import Testing
import Foundation
@testable import LiveTranscribe

@Suite("SpeakerHeuristic")
struct SpeakerHeuristicTests {

    private func partial(_ text: String, silenceMs: Int = 0) -> PartialTranscript {
        PartialTranscript(text: text, isFinal: true, audioStart: 0, audioEnd: 1, silenceBeforeMs: silenceMs)
    }

    @Test("1:1 mode keeps a single rolling speaker")
    func oneToOneStable() {
        var h = SpeakerHeuristic(mode: .oneToOne)
        let a = h.line(for: partial("hi"))
        let b = h.line(for: partial("how are you", silenceMs: 5_000))
        #expect(a.speaker.id == b.speaker.id)
    }

    @Test("Group mode rotates speaker on long pauses")
    func groupRotation() {
        var h = SpeakerHeuristic(mode: .group, pauseThresholdMs: 1200)
        _ = h.line(for: partial("first")) // Speaker 1
        let second = h.line(for: partial("second", silenceMs: 0)) // no rotation
        let third = h.line(for: partial("third", silenceMs: 1500)) // rotates → Speaker 2
        #expect(second.speaker.id == "Speaker 1")
        #expect(third.speaker.id == "Speaker 2")
    }

    @Test("Group mode wraps after maxSpeakers")
    func groupWraps() {
        var h = SpeakerHeuristic(mode: .group, pauseThresholdMs: 1000, maxSpeakers: 3)
        // Each line forces a rotation by passing a long silence.
        let one = h.line(for: partial("a"))                                  // 1
        let two = h.line(for: partial("b", silenceMs: 2000))                 // 2
        let three = h.line(for: partial("c", silenceMs: 2000))               // 3
        let four = h.line(for: partial("d", silenceMs: 2000))                // wraps to 1
        #expect(one.speaker.id == "Speaker 1")
        #expect(two.speaker.id == "Speaker 2")
        #expect(three.speaker.id == "Speaker 3")
        #expect(four.speaker.id == "Speaker 1")
    }

    @Test("Speaker.numbered assigns distinct color roles")
    func numberedColors() {
        let s1 = Speaker.numbered(1)
        let s2 = Speaker.numbered(2)
        let s5 = Speaker.numbered(5) // wraps
        #expect(s1.colorRole != s2.colorRole)
        #expect(s1.colorRole == s5.colorRole)
    }
}
