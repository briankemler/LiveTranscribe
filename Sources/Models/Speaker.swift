import SwiftUI

/// Identity for one voice in the transcript. Matches the source `SPK` map.
struct Speaker: Sendable, Hashable, Identifiable {
    let id: String       // canonical name, e.g. "Maya"
    let displayName: String
    let initial: String
    let colorRole: SpeakerColorRole

    enum SpeakerColorRole: Sendable {
        case a, b, c, d, e
    }

    func color(in theme: Theme) -> Color {
        switch colorRole {
        case .a: theme.spkA
        case .b: theme.spkB
        case .c: theme.spkC
        case .d: theme.spkD
        case .e: theme.spkE
        }
    }
}

extension Speaker {
    static let you    = Speaker(id: "You",    displayName: "You",    initial: "Y", colorRole: .a)
    static let maya   = Speaker(id: "Maya",   displayName: "Maya",   initial: "M", colorRole: .b)
    static let jordan = Speaker(id: "Jordan", displayName: "Jordan", initial: "J", colorRole: .c)
    static let priya  = Speaker(id: "Priya",  displayName: "Priya",  initial: "P", colorRole: .d)
    static let sam    = Speaker(id: "Sam",    displayName: "Sam",    initial: "S", colorRole: .b)
    static let mom    = Speaker(id: "Mom",    displayName: "Mom",    initial: "M", colorRole: .d)

    static let known: [Speaker] = [.you, .maya, .jordan, .priya, .sam, .mom]
    static func find(_ name: String) -> Speaker {
        known.first { $0.id == name } ?? Speaker(id: name, displayName: name, initial: String(name.prefix(1)), colorRole: .a)
    }
}

/// One transcribed line. The optional `emphasis` is a substring rendered serif-italic in the accent.
struct TranscriptLine: Sendable, Hashable, Identifiable {
    let id: UUID
    let speaker: Speaker
    let text: String
    let emphasis: String?
    let timestamp: String?

    init(id: UUID = UUID(), speaker: Speaker, text: String, emphasis: String? = nil, timestamp: String? = nil) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.emphasis = emphasis
        self.timestamp = timestamp
    }
}

enum LiveMode: Sendable, Hashable {
    case oneToOne
    case group
}

enum SampleScripts {
    static let oneToOne: [TranscriptLine] = [
        .init(speaker: .maya, text: "I had the most ridiculous run this morning."),
        .init(speaker: .you,  text: "Oh no, what happened?"),
        .init(speaker: .maya, text: "A goose chased me around the lake. Like, committed."),
        .init(speaker: .you,  text: "You okay?"),
        .init(speaker: .maya, text: "Honestly, the background noise helped me focus. And the espresso is unreal", emphasis: "unreal"),
    ]

    static let group: [TranscriptLine] = [
        .init(speaker: .jordan, text: "Wait, you actually finished the marathon?"),
        .init(speaker: .maya,   text: "Four hours twelve. Knees still hate me."),
        .init(speaker: .priya,  text: "Okay but the real question is what's for dessert."),
        .init(speaker: .you,    text: "There's tiramisu in the fridge."),
        .init(speaker: .jordan, text: "You're a hero, I'll grab plates", emphasis: "hero"),
    ]
}
