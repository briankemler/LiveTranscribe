import SwiftUI

/// Color + typography tokens for one Earshot palette.
/// Matches the JS `T = { ... }` token set from the design prototype.
struct Theme: Sendable, Equatable {
    // Backgrounds
    let bg: Color
    let bgSoft: Color
    let surface: Color
    let surfaceHi: Color
    let surfaceLo: Color

    // Text
    let ink: Color
    let inkSoft: Color
    let inkMute: Color
    let inkDim: Color

    // Hairlines
    let line: Color
    let lineHi: Color

    // Accent (the "peach" in the source — name kept abstract because it's per-palette)
    let accent: Color
    let accentDeep: Color
    let accentSoft: Color
    let accentGlow: Color

    // Speaker palette
    let spkA: Color
    let spkB: Color
    let spkC: Color
    let spkD: Color
    let spkE: Color

    // Sound semantics
    let alert: Color
    let alertSoft: Color
    let ambient: Color
    let ambientSoft: Color
    let social: Color
    let socialSoft: Color

    /// Used for solid-on-accent text (e.g. text on the peach button).
    /// Always reads against `accent`, so this is bg in dark themes and ink in paper.
    let onAccent: Color

    /// True when the palette is light (Paper) — flips a few iOS chrome bits.
    let isLight: Bool
}

// MARK: - Convenience colors

extension Color {
    /// Hex helper. Accepts `#RRGGBB`, `RRGGBB`, `#RRGGBBAA`, or `RRGGBBAA`.
    init(hex: String, alpha: Double? = nil) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 6:
            r = Double((v & 0xFF0000) >> 16) / 255
            g = Double((v & 0x00FF00) >> 8) / 255
            b = Double( v & 0x0000FF) / 255
            a = alpha ?? 1
        case 8:
            r = Double((v & 0xFF00_0000) >> 24) / 255
            g = Double((v & 0x00FF_0000) >> 16) / 255
            b = Double((v & 0x0000_FF00) >> 8) / 255
            a = alpha ?? Double(v & 0x0000_00FF) / 255
        default:
            r = 0; g = 0; b = 0; a = alpha ?? 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Palettes

extension Theme {
    /// Warm — peach on warm dark brown. Default.
    static let warm = Theme(
        bg:        Color(hex: "1a1612"),
        bgSoft:    Color(hex: "241e18"),
        surface:   Color(hex: "2a231d"),
        surfaceHi: Color(hex: "332b23"),
        surfaceLo: Color(hex: "ffffff", alpha: 0.04),

        ink:     Color(hex: "f5ede0"),
        inkSoft: Color(hex: "f5ede0", alpha: 0.72),
        inkMute: Color(hex: "f5ede0", alpha: 0.45),
        inkDim:  Color(hex: "f5ede0", alpha: 0.28),

        line:   Color(hex: "f5ede0", alpha: 0.08),
        lineHi: Color(hex: "f5ede0", alpha: 0.16),

        accent:     Color(hex: "e89878"),
        accentDeep: Color(hex: "c96442"),
        accentSoft: Color(hex: "e89878", alpha: 0.18),
        accentGlow: Color(hex: "e89878", alpha: 0.35),

        spkA: Color(hex: "e89878"),
        spkB: Color(hex: "7ab8a4"),
        spkC: Color(hex: "e8b85a"),
        spkD: Color(hex: "b89cd8"),
        spkE: Color(hex: "e87878"),

        alert:       Color(hex: "e85a45"),
        alertSoft:   Color(hex: "e85a45", alpha: 0.22),
        ambient:     Color(hex: "f5ede0", alpha: 0.45),
        ambientSoft: Color(hex: "f5ede0", alpha: 0.06),
        social:      Color(hex: "7ab8a4"),
        socialSoft:  Color(hex: "7ab8a4", alpha: 0.18),

        onAccent: Color(hex: "1a1612"),
        isLight: false
    )

    /// Midnight — deep blue accent on near-black. (chat: confident blue 5b8def)
    static let midnight = Theme(
        bg:        Color(hex: "0c0e14"),
        bgSoft:    Color(hex: "12151d"),
        surface:   Color(hex: "171b26"),
        surfaceHi: Color(hex: "1f2433"),
        surfaceLo: Color(hex: "ffffff", alpha: 0.04),

        ink:     Color(hex: "eef3ff"),
        inkSoft: Color(hex: "eef3ff", alpha: 0.72),
        inkMute: Color(hex: "eef3ff", alpha: 0.45),
        inkDim:  Color(hex: "eef3ff", alpha: 0.28),

        line:   Color(hex: "eef3ff", alpha: 0.08),
        lineHi: Color(hex: "eef3ff", alpha: 0.16),

        accent:     Color(hex: "5b8def"),
        accentDeep: Color(hex: "3a6cd9"),
        accentSoft: Color(hex: "5b8def", alpha: 0.18),
        accentGlow: Color(hex: "5b8def", alpha: 0.35),

        spkA: Color(hex: "5b8def"),
        spkB: Color(hex: "55c6c2"),
        spkC: Color(hex: "e8b85a"),
        spkD: Color(hex: "b89cd8"),
        spkE: Color(hex: "ef6a6a"),

        alert:       Color(hex: "ef6a6a"),
        alertSoft:   Color(hex: "ef6a6a", alpha: 0.22),
        ambient:     Color(hex: "eef3ff", alpha: 0.45),
        ambientSoft: Color(hex: "eef3ff", alpha: 0.06),
        social:      Color(hex: "55c6c2"),
        socialSoft:  Color(hex: "55c6c2", alpha: 0.18),

        onAccent: Color(hex: "0c0e14"),
        isLight: false
    )

    /// Paper — deep coral on warm cream. Light mode.
    static let paper = Theme(
        bg:        Color(hex: "f7f1e6"),
        bgSoft:    Color(hex: "ede5d4"),
        surface:   Color(hex: "ffffff"),
        surfaceHi: Color(hex: "fffaef"),
        surfaceLo: Color(hex: "1f1a13", alpha: 0.04),

        ink:     Color(hex: "1f1a13"),
        inkSoft: Color(hex: "1f1a13", alpha: 0.72),
        inkMute: Color(hex: "1f1a13", alpha: 0.50),
        inkDim:  Color(hex: "1f1a13", alpha: 0.30),

        line:   Color(hex: "1f1a13", alpha: 0.08),
        lineHi: Color(hex: "1f1a13", alpha: 0.16),

        accent:     Color(hex: "c34a2c"),
        accentDeep: Color(hex: "8e3320"),
        accentSoft: Color(hex: "c34a2c", alpha: 0.14),
        accentGlow: Color(hex: "c34a2c", alpha: 0.30),

        // Ink-on-paper speaker palette
        spkA: Color(hex: "c34a2c"),
        spkB: Color(hex: "2f5d3f"),
        spkC: Color(hex: "8a6210"),
        spkD: Color(hex: "5e3a6e"),
        spkE: Color(hex: "8b1f1f"),

        alert:       Color(hex: "b1331c"),
        alertSoft:   Color(hex: "b1331c", alpha: 0.16),
        ambient:     Color(hex: "1f1a13", alpha: 0.50),
        ambientSoft: Color(hex: "1f1a13", alpha: 0.05),
        social:      Color(hex: "2f5d3f"),
        socialSoft:  Color(hex: "2f5d3f", alpha: 0.14),

        onAccent: Color.white,
        isLight: true
    )

    static let all: [(id: PaletteID, theme: Theme)] = [
        (.warm, .warm),
        (.midnight, .midnight),
        (.paper, .paper),
    ]
}

enum PaletteID: String, CaseIterable, Sendable, Identifiable, Codable {
    case warm, midnight, paper
    var id: String { rawValue }
    var theme: Theme {
        switch self {
        case .warm: .warm
        case .midnight: .midnight
        case .paper: .paper
        }
    }
    var label: String {
        switch self {
        case .warm: "Warm"
        case .midnight: "Midnight"
        case .paper: "Paper"
        }
    }
}

// MARK: - Environment

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .warm
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
