import Foundation

/// Stitches successive *batch* diarization passes into one stable, monotonically-growing speaker
/// timeline in absolute audio-time seconds.
///
/// Why this exists: SpeakerKit is batch-only and re-clusters from scratch on every `diarize`
/// call, so local cluster id `0` in pass N may be a different person than cluster `0` in pass
/// N+1. To get *live* labels we run `diarize` repeatedly over a rolling, overlapping window and
/// re-identify speakers across passes by **temporal overlap**: a fresh cluster that overlaps an
/// established speaker's recent speech is judged the same person. Clusters with no overlap are
/// allocated fresh stable ids that never decrease.
///
/// This is the "best-effort" heart of live diarization — stable ids in the steady state, with the
/// most recent (still-provisional) region occasionally re-snapping as more audio arrives. It's a
/// pure value type with no model/audio dependency, so it's fully unit-testable against synthetic
/// `DiarizedSegment`s.
///
/// Contract: callers feed segments already offset to **absolute** audio time, and successive
/// windows must overlap (window ≫ stride) — otherwise every pass looks brand-new and ids explode.
struct SpeakerTimeline {

    /// One stable-speaker activity span in absolute audio-time seconds.
    struct Span: Sendable, Hashable {
        /// Stable, 0-indexed speaker id. Allocated in first-spoken order; never reused/decreased.
        let speaker: Int
        var start: TimeInterval
        var end: TimeInterval
    }

    /// Minimum overlap (seconds) for a fresh cluster to be matched to an existing speaker. Below
    /// this it's treated as a new speaker.
    var minOverlapSeconds: TimeInterval = 0.2
    /// Same-speaker spans closer than this gap (seconds) are merged into one.
    var mergeGapSeconds: TimeInterval = 0.4
    /// Minimum total speech (seconds) an *unmatched* cluster must have in a pass before it earns a
    /// brand-new stable speaker id. Brief blips from pyannote over-segmentation fall below this and
    /// are dropped (their audio stays uncovered → the line keeps its sticky label) rather than
    /// flashing a spurious "Speaker N". A genuine new voice clears the bar as they keep talking.
    var minNewSpeakerSeconds: TimeInterval = 1.0
    /// Hard ceiling on the number of distinct stable speakers. Once reached, an unmatched cluster
    /// is *folded into the nearest existing speaker* instead of minting a new id — this is what
    /// stops "keeps cycling new speakers" on long conversations. Set to the user's expected count
    /// (or a sane max in Auto). Default `.max` = uncapped (the pure-type default; production sets it).
    var maxSpeakers: Int = .max

    /// The assembled, merged timeline, sorted by start time.
    private(set) var spans: [Span] = []
    private var nextSpeakerId: Int = 0

    /// Total distinct stable speakers allocated so far (monotonic, ≤ `maxSpeakers`).
    var speakerCount: Int { nextSpeakerId }

    init(
        minOverlapSeconds: TimeInterval = 0.2,
        mergeGapSeconds: TimeInterval = 0.4,
        minNewSpeakerSeconds: TimeInterval = 1.0,
        maxSpeakers: Int = .max
    ) {
        self.minOverlapSeconds = minOverlapSeconds
        self.mergeGapSeconds = mergeGapSeconds
        self.minNewSpeakerSeconds = minNewSpeakerSeconds
        self.maxSpeakers = maxSpeakers
    }

    // MARK: - Ingest

    /// Fold one diarization pass into the timeline. The pass authoritatively re-describes
    /// `[windowStart, windowEnd]`; spans outside that range are preserved. Segments are clipped to
    /// the window. Returns the `localClusterId → stableSpeakerId` mapping used for this pass.
    @discardableResult
    mutating func ingest(
        _ segments: [DiarizedSegment],
        windowStart: TimeInterval,
        windowEnd: TimeInterval
    ) -> [Int: Int] {
        guard windowEnd > windowStart else { return [:] }

        // Group the new pass by local cluster id, clipped to the window.
        var local: [Int: [Interval]] = [:]
        for s in segments where s.end > s.start {
            let a = max(s.start, windowStart)
            let b = min(s.end, windowEnd)
            guard b > a else { continue }
            local[s.speakerId, default: []].append(Interval(start: a, end: b))
        }
        guard !local.isEmpty else {
            // Empty pass over a covered window = silence; clear that window so stale labels don't
            // linger, but keep everything outside it.
            spans = clipOutWindow(windowStart, windowEnd, from: spans)
            return [:]
        }

        // Existing speakers' intervals clipped to the window — the evidence for re-identification.
        let existing = spansClipped(to: windowStart, windowEnd)

        // Build the overlap matrix and assign greedily by descending overlap (deterministic
        // tie-break: smaller global id, then smaller local id).
        var candidates: [(local: Int, global: Int, overlap: TimeInterval)] = []
        for (lc, lints) in local {
            for (g, gints) in existing {
                let ov = totalOverlap(lints, gints)
                if ov >= minOverlapSeconds { candidates.append((lc, g, ov)) }
            }
        }
        candidates.sort {
            if $0.overlap != $1.overlap { return $0.overlap > $1.overlap }
            if $0.global != $1.global { return $0.global < $1.global }
            return $0.local < $1.local
        }

        var mapping: [Int: Int] = [:]   // local -> global
        var usedGlobal: Set<Int> = []
        for c in candidates {
            if mapping[c.local] != nil || usedGlobal.contains(c.global) { continue }
            mapping[c.local] = c.global
            usedGlobal.insert(c.global)
        }

        // Unmatched local clusters become new stable speakers, numbered in first-spoken order so
        // the earliest talker gets the lowest id — but only if they've spoken enough this pass.
        // Brief blips (below `minNewSpeakerSeconds`) are left unmapped and dropped, so pyannote
        // over-segmentation can't spawn a spurious "Speaker N".
        let unmatched = local.keys.filter { mapping[$0] == nil }
            .sorted { earliestStart(local[$0]) < earliestStart(local[$1]) }
        for lc in unmatched {
            let ints = local[lc] ?? []
            if nextSpeakerId < maxSpeakers {
                // Room for a new speaker — but only if they've spoken enough to clear the blip gate.
                let duration = ints.reduce(0) { $0 + ($1.end - $1.start) }
                guard duration >= minNewSpeakerSeconds else { continue }
                mapping[lc] = nextSpeakerId
                nextSpeakerId += 1
            } else if let fold = foldTarget(for: ints) {
                // Speaker cap reached: attribute this cluster to the nearest existing speaker
                // rather than spawn a spurious new one. This is the anti-runaway clamp.
                mapping[lc] = fold
            }
        }

        // Rebuild: drop the window region from existing spans, splice in the newly-mapped pass.
        var rebuilt = clipOutWindow(windowStart, windowEnd, from: spans)
        for (lc, ints) in local {
            guard let g = mapping[lc] else { continue }
            for iv in ints { rebuilt.append(Span(speaker: g, start: iv.start, end: iv.end)) }
        }
        spans = merged(rebuilt)
        return mapping
    }

    // MARK: - Lookup

    /// Stable speaker id active at absolute audio time `t`, or nil if no one is. On overlapping
    /// speech, returns the speaker whose span center is closest to `t`.
    func speaker(at t: TimeInterval) -> Int? {
        let hits = spans.filter { $0.start <= t && t < $0.end }
        if hits.isEmpty { return nil }
        if hits.count == 1 { return hits[0].speaker }
        return hits.min {
            abs(($0.start + $0.end) / 2 - t) < abs(($1.start + $1.end) / 2 - t)
        }?.speaker
    }

    /// Stable speaker id that held the floor for the most time during `[start, end]`, or nil if
    /// the range has no coverage. This is the attribution a transcript line wants (a line spans a
    /// time window, not an instant). Ties break toward the lower (earlier-seen) speaker id.
    func dominantSpeaker(from start: TimeInterval, to end: TimeInterval) -> Int? {
        guard end > start else { return speaker(at: start) }
        var totals: [Int: TimeInterval] = [:]
        for sp in spans {
            let a = max(sp.start, start)
            let b = min(sp.end, end)
            if b > a { totals[sp.speaker, default: 0] += (b - a) }
        }
        guard !totals.isEmpty else { return nil }
        return totals.max {
            if $0.value != $1.value { return $0.value < $1.value }
            return $0.key > $1.key   // tie → prefer smaller id (it's the *max*, so invert)
        }?.key
    }

    // MARK: - Helpers

    private struct Interval { let start: TimeInterval; let end: TimeInterval }

    private func earliestStart(_ ints: [Interval]?) -> TimeInterval {
        ints?.map(\.start).min() ?? .greatestFiniteMagnitude
    }

    private func totalOverlap(_ a: [Interval], _ b: [Interval]) -> TimeInterval {
        var sum: TimeInterval = 0
        for x in a {
            for y in b {
                let lo = max(x.start, y.start)
                let hi = min(x.end, y.end)
                if hi > lo { sum += hi - lo }
            }
        }
        return sum
    }

    /// When the speaker cap is reached, pick the best existing speaker to absorb an unmatched
    /// cluster: the one it overlaps most in time, else the one nearest in time, else speaker 0.
    /// (Phase B will replace this time-based heuristic with voice-embedding similarity.)
    private func foldTarget(for ints: [Interval]) -> Int? {
        guard nextSpeakerId > 0, let probe = ints.first?.start else { return nil }
        var bestOverlap: (speaker: Int, overlap: TimeInterval)?
        for (speaker, list) in Dictionary(grouping: spans, by: \.speaker) {
            let gints = list.map { Interval(start: $0.start, end: $0.end) }
            let ov = totalOverlap(ints, gints)
            if ov > 0, bestOverlap == nil || ov > bestOverlap!.overlap {
                bestOverlap = (speaker, ov)
            }
        }
        if let best = bestOverlap { return best.speaker }
        // No time overlap with anyone — fall back to the speaker nearest in time.
        var nearest: (speaker: Int, gap: TimeInterval)?
        for sp in spans {
            let gap = min(abs(sp.start - probe), abs(sp.end - probe))
            if nearest == nil || gap < nearest!.gap { nearest = (sp.speaker, gap) }
        }
        return nearest?.speaker ?? 0
    }

    private func spansClipped(to start: TimeInterval, _ end: TimeInterval) -> [Int: [Interval]] {
        var out: [Int: [Interval]] = [:]
        for sp in spans {
            let a = max(sp.start, start)
            let b = min(sp.end, end)
            if b > a { out[sp.speaker, default: []].append(Interval(start: a, end: b)) }
        }
        return out
    }

    /// Remove the `[start, end]` region from a span list, keeping the parts before/after.
    private func clipOutWindow(_ start: TimeInterval, _ end: TimeInterval, from input: [Span]) -> [Span] {
        var kept: [Span] = []
        for sp in input {
            if sp.end <= start || sp.start >= end { kept.append(sp); continue }
            if sp.start < start { kept.append(Span(speaker: sp.speaker, start: sp.start, end: start)) }
            if sp.end > end { kept.append(Span(speaker: sp.speaker, start: end, end: sp.end)) }
        }
        return kept
    }

    /// Merge same-speaker spans separated by ≤ `mergeGapSeconds`; return sorted by start.
    private func merged(_ input: [Span]) -> [Span] {
        var out: [Span] = []
        for list in Dictionary(grouping: input, by: \.speaker).values {
            let sorted = list.sorted { $0.start < $1.start }
            guard var cur = sorted.first else { continue }
            for s in sorted.dropFirst() {
                if s.start <= cur.end + mergeGapSeconds {
                    cur.end = max(cur.end, s.end)
                } else {
                    out.append(cur)
                    cur = s
                }
            }
            out.append(cur)
        }
        out.sort { $0.start != $1.start ? $0.start < $1.start : $0.speaker < $1.speaker }
        return out
    }
}
