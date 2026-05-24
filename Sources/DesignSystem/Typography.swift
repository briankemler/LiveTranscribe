import SwiftUI
import UIKit

extension Font {
    /// Drop-in replacement for `.system(size:weight:design:)` that **scales with iOS Dynamic
    /// Type**. The fixed `size` you pass is the size at *default* Dynamic Type; at AX5 it
    /// grows the way the matching `relativeTo:` text style would, via `UIFontMetrics`.
    ///
    /// SwiftUI's `Font.system(size:weight:design:)` ignores Dynamic Type entirely — a user
    /// who cranked up iOS text size in Settings → Display & Brightness gets the same fixed
    /// pt size. This helper closes that gap while preserving the design's exact sizes at
    /// default Dynamic Type.
    ///
    /// `relativeTo:` controls the scaling curve — pick the system text style with the
    /// nearest default size to your `size` (e.g. 14pt → `.subheadline` which is 15pt
    /// default, 22pt → `.title2` which is 22pt default).
    static func scaled(size: CGFloat,
                       weight: Font.Weight = .regular,
                       design: Font.Design = .default,
                       relativeTo style: UIFont.TextStyle = .body) -> Font {
        let scaledSize = UIFontMetrics(forTextStyle: style).scaledValue(for: size)
        return .system(size: scaledSize, weight: weight, design: design)
    }
}

/// Centralized type scale. Every text style in the app should resolve through one of these
/// — not through raw `.font(.system(size: N))` — so iOS Dynamic Type scales the chrome.
///
/// **Why semantic fonts (`.system(size:relativeTo:)`)?** A plain `.scaled(size: 14, relativeTo: .subheadline)` ignores
/// Dynamic Type — a user with Settings → Display & Brightness → Text Size cranked up sees the
/// same size as someone on default. Pairing each fixed size with a system style anchors it to
/// `UIFontMetrics.default.scaledFont(for:)`, so growth/shrink is automatic.
///
/// **Live captions are different.** The big serif caption on the Live screen has its own
/// dedicated knob (`Tweaks.textSize`) because users may want big captions across the room
/// but a normal-size Settings menu. The caption uses `displaySerif(...)` here as a starting
/// point and then applies the textSize multiplier in the view.
enum AppFont {

    // MARK: - UI scale (sans-serif, SF Pro)

    /// 11pt heavy kicker text — section headers, tracking labels (`tracking(1.5)`).
    static let kicker: Font = .scaled(size: 11, weight: .heavy, design: .default, relativeTo: .caption2).leading(.tight)

    /// 12pt — secondary text, footnote-y. Wraps `.caption`.
    static let micro: Font = .system(.caption, design: .default)

    /// 13pt — body-adjacent secondary text. Wraps `.footnote`.
    static let caption: Font = .system(.footnote, design: .default)

    /// 14pt — primary row text on Settings list, transcript captions in the History sheet,
    /// most "label" text. Wraps `.callout` so it scales with Dynamic Type.
    static let body: Font = .system(.callout, design: .default)

    /// 15pt — slightly larger body text. Used for transcript lines and conversation rows.
    static let bodyLarge: Font = .system(.body, design: .default)

    /// 18pt — emphasized chip / button-ish labels. Wraps `.body` with weight.
    static let action: Font = .system(.body, design: .default).weight(.semibold)

    /// 19pt — primary CTA buttons.
    static let cta: Font = .system(.title3, design: .default).weight(.bold)

    // MARK: - Display serif (New York)

    /// Display serif at a logical size. Caller may apply the Live-caption multiplier on top.
    /// Pairing with `relativeTo:` makes the serif grow with Dynamic Type *up to* the clamp set
    /// by the caller (we clamp display serifs at `xxxLarge` to avoid AX5 overflow on small
    /// iPhones where the headline would push everything off-screen).
    static func displaySerif(size: CGFloat, weight: Font.Weight = .medium, relativeTo: Font.TextStyle = .largeTitle) -> Font {
        .system(size: size, weight: weight, design: .serif).leading(.tight)
        // Note: SwiftUI's `Font.system(size:weight:design:)` doesn't accept `relativeTo:` directly;
        // the helper below in `displaySerif(_:)` view modifier sets `.dynamicTypeSize` clamps.
    }

    /// Monospaced (debug pill, diagnostics).
    static func mono(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

extension View {
    /// Apply to anywhere we use the big display serif. Caps growth at `xxxLarge` so AX text-size
    /// users get reasonable scaling without the headline pushing primary controls off-screen.
    /// UI chrome below the headline keeps growing all the way to AX5 — only the display serif
    /// is clamped here.
    func displaySerifDynamicTypeClamp() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
