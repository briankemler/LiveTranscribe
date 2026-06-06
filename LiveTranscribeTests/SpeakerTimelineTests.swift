import Testing
import Foundation
@testable import LiveTranscribe

@Suite("SpeakerTimeline")
struct SpeakerTimelineTests {

    private func seg(_ speaker: Int, _ start: TimeInterval, _ end: TimeInterval) -> DiarizedSegment {
        DiarizedSegment(speakerId: speaker, start: start, end: end)
    }

    // MARK: - First pass

    @Test("First pass allocates stable ids in first-spoken order")
    func firstPassOrdering() {
        var timeline = SpeakerTimeline()
        // Local cluster 7 speaks first (0–2s), cluster 3 speaks second (2–4s). Stable ids should
        // be assigned by start time, not by local cluster number.
        let mapping = timeline.ingest(
            [seg(7, 0, 2), seg(3, 2, 4)],
            windowStart: 0, windowEnd: 4
        )
        #expect(mapping[7] == 0)
        #expect(mapping[3] == 1)
        #expect(timeline.speakerCount == 2)
        #expect(timeline.speaker(at: 1) == 0)
        #expect(timeline.speaker(at: 3) == 1)
    }

    // MARK: - Stitching stability

    @Test("Renumbered clusters in the next pass stitch to the same stable ids")
    func stitchingStability() {
        var timeline = SpeakerTimeline()
        // Pass 1 over [0,4]: A speaks 0–2 (local 0), B speaks 2–4 (local 1).
        timeline.ingest([seg(0, 0, 2), seg(1, 2, 4)], windowStart: 0, windowEnd: 4)
        #expect(timeline.speaker(at: 1) == 0)
        #expect(timeline.speaker(at: 3) == 1)

        // Pass 2 over [2,6], window overlaps [2,4]. Pyannote renumbers: the SAME B (2–4) is now
        // local 1→ but A is gone; the person at 2–4 is local 5, and a continuation 4–6 local 5.
        // Whoever overlaps stable speaker 1's 2–4 region must remain stable id 1.
        timeline.ingest([seg(5, 2, 6)], windowStart: 2, windowEnd: 6)
        #expect(timeline.speaker(at: 3) == 1)   // unchanged — re-identified by overlap
        #expect(timeline.speaker(at: 5) == 1)   // continuation of the same speaker
        #expect(timeline.speaker(at: 1) == 0)   // untouched span before the window survives
        #expect(timeline.speakerCount == 2)     // no spurious new speaker
    }

    @Test("Swapped local cluster numbers across passes stay stable")
    func swappedClusters() {
        var timeline = SpeakerTimeline()
        // Pass 1: speaker-at-0–3 = local 0, speaker-at-3–6 = local 1.
        timeline.ingest([seg(0, 0, 3), seg(1, 3, 6)], windowStart: 0, windowEnd: 6)
        let first = (timeline.speaker(at: 1), timeline.speaker(at: 4))
        #expect(first == (0, 1))

        // Pass 2 over [0,6] but pyannote flips the labels: same people, local ids swapped.
        timeline.ingest([seg(1, 0, 3), seg(0, 3, 6)], windowStart: 0, windowEnd: 6)
        // Overlap re-identification must keep the stable ids pinned to the people, not the labels.
        #expect(timeline.speaker(at: 1) == 0)
        #expect(timeline.speaker(at: 4) == 1)
        #expect(timeline.speakerCount == 2)
    }

    // MARK: - New speaker append

    @Test("A genuinely new voice appends a new id without disturbing existing ones")
    func newSpeakerAppends() {
        var timeline = SpeakerTimeline()
        timeline.ingest([seg(0, 0, 2), seg(1, 2, 4)], windowStart: 0, windowEnd: 4)
        #expect(timeline.speakerCount == 2)

        // Pass 2 over [2,6]: established speaker 1 continues (2–4), and a brand-new third person
        // speaks 4–6 with no overlap to anyone → must get stable id 2.
        timeline.ingest([seg(1, 2, 4), seg(9, 4, 6)], windowStart: 2, windowEnd: 6)
        #expect(timeline.speaker(at: 3) == 1)
        #expect(timeline.speaker(at: 5) == 2)
        #expect(timeline.speakerCount == 3)
    }

    @Test("Stable id count is monotonic across many passes")
    func monotonicIds() {
        var timeline = SpeakerTimeline()
        var lastCount = 0
        for k in 0..<5 {
            let start = TimeInterval(k * 2)
            timeline.ingest([seg(0, start, start + 2)], windowStart: start, windowEnd: start + 2)
            #expect(timeline.speakerCount >= lastCount)
            lastCount = timeline.speakerCount
        }
    }

    // MARK: - Line attribution

    @Test("dominantSpeaker picks the floor-holder over a line's time window")
    func dominantSpeaker() {
        var timeline = SpeakerTimeline()
        // Speaker 0: 0–1s, Speaker 1: 1–5s. A line spanning 0.5–5 is mostly speaker 1.
        timeline.ingest([seg(0, 0, 1), seg(1, 1, 5)], windowStart: 0, windowEnd: 5)
        #expect(timeline.dominantSpeaker(from: 0.5, to: 5) == 1)
        #expect(timeline.dominantSpeaker(from: 0, to: 0.8) == 0)
    }

    @Test("dominantSpeaker returns nil over an uncovered range")
    func dominantSpeakerNoCoverage() {
        var timeline = SpeakerTimeline()
        timeline.ingest([seg(0, 0, 2)], windowStart: 0, windowEnd: 2)
        #expect(timeline.dominantSpeaker(from: 10, to: 12) == nil)
    }

    // MARK: - Silence

    @Test("An empty pass clears its window but preserves earlier spans")
    func emptyPassClearsWindow() {
        var timeline = SpeakerTimeline()
        timeline.ingest([seg(0, 0, 2), seg(1, 4, 6)], windowStart: 0, windowEnd: 6)
        #expect(timeline.speaker(at: 5) == 1)
        // Silence over [4,8] clears the latter half.
        timeline.ingest([], windowStart: 4, windowEnd: 8)
        #expect(timeline.speaker(at: 5) == nil)
        #expect(timeline.speaker(at: 1) == 0)   // earlier span survives
    }

    // MARK: - Overlap below threshold

    @Test("A brief unmatched blip does not spawn a spurious speaker")
    func briefBlipDropped() {
        var timeline = SpeakerTimeline()   // default minNewSpeakerSeconds = 1.0
        // One established speaker, plus a 0.4 s blip that overlaps no one → below the 1.0 s floor.
        timeline.ingest([seg(0, 0, 4), seg(7, 4.2, 4.6)], windowStart: 0, windowEnd: 6)
        #expect(timeline.speakerCount == 1)          // blip dropped, no Speaker 2
        #expect(timeline.speaker(at: 4.4) == nil)    // its audio is left uncovered
        #expect(timeline.speaker(at: 2) == 0)
    }

    @Test("Below-threshold overlap is treated as a new speaker")
    func subThresholdOverlapIsNew() {
        var timeline = SpeakerTimeline(minOverlapSeconds: 0.5, mergeGapSeconds: 0.4)
        timeline.ingest([seg(0, 0, 3)], windowStart: 0, windowEnd: 3)
        // Next pass overlaps only 0.1s with the existing speaker — under the 0.5s floor → new id.
        timeline.ingest([seg(0, 2.9, 6)], windowStart: 2.9, windowEnd: 6)
        #expect(timeline.speakerCount == 2)
        #expect(timeline.speaker(at: 5) == 1)
    }

    // MARK: - Speaker cap

    @Test("Speaker cap folds extra clusters into existing speakers, never minting new ids")
    func speakerCapClamps() {
        var timeline = SpeakerTimeline(maxSpeakers: 2)
        // Three distinct, well-separated voices in one pass, but the cap is 2.
        timeline.ingest([seg(0, 0, 3), seg(1, 3, 6), seg(2, 6, 9)], windowStart: 0, windowEnd: 9)
        #expect(timeline.speakerCount == 2)               // never exceeds the cap
        #expect(timeline.speaker(at: 1) == 0)             // first two get ids 0 and 1
        #expect(timeline.speaker(at: 4) == 1)
        let third = timeline.speaker(at: 7)               // the over-cap voice folds into one of them
        #expect(third == 0 || third == 1)
    }

    @Test("Under the cap, new speakers still append normally")
    func capAllowsUpToLimit() {
        var timeline = SpeakerTimeline(maxSpeakers: 4)
        timeline.ingest([seg(0, 0, 2), seg(1, 2, 4), seg(2, 4, 6)], windowStart: 0, windowEnd: 6)
        #expect(timeline.speakerCount == 3)               // below the cap → all three allocate
    }
}
