# Live Transcribe — Captions Screen Handoff (Rev 2)

The captions screen is the most-used surface in Live Transcribe. This spec replaces the prior screen with a minimal, focus-first layout: maximum legibility on the words themselves, a single always-visible status pill, an auto-hiding bottom bar for actions, and a quick-settings bottom sheet reachable from that bar.

Companion file: `captions-rev2.jsx` — interactive reference implementation. Open `Live Transcribe — Captions Rev 2.html` to see all four states (live hidden / live revealed / settings sheet / silence).

---

## Visual reference

| State | Description |
|---|---|
| **Live · controls hidden** | Default state. Captions front and center. A small status pill top-left. An optional sound tag top-right. No other chrome. |
| **Live · controls revealed** | Tap anywhere → floating bar slides in from below with cog · star · pause. Auto-hides after 3000ms of no interaction. |
| **Quick settings sheet** | Tap cog → bottom sheet slides up: text size segmented control, ambient-sounds toggle, vibrate-on-alerts toggle, "all settings" link. Tap outside or grabber to dismiss. |
| **Silence** | When no speech detected for >5s: last line dims to 22% opacity, a centered pill shows "N seconds of silence" with a breathing dot. Status pill keeps confirming mic is on. |

---

## Layout (380×800 viewport reference)

```
┌──────────────────────────────────┐
│ [● ● ● Listening · 0:08:42]      │   ← Status pill (always visible)
│                          ♫ jazz  │   ← Right-margin tag (optional, ambient)
│                                  │
│  A goose chased me around the    │   ← Previous line — fontDisplay, 20px, 22% opacity
│  lake.                           │
│                                  │
│  And the espresso is unreal│     │   ← Current line — fontDisplay, 32px, 100% opacity
│                                  │     Peach caret (▍) blinks at end
│                                  │
│  …                               │
│                                  │
│         TAP FOR CONTROLS         │   ← Hint, only shown when bar hidden
│  ╭────────────────────────────╮  │
│  │  ⚙   ☆            ┃┃        │  │   ← Floating bar — auto-hides after 3s
│  ╰────────────────────────────╯  │
└──────────────────────────────────┘
```

### Padding & spacing
- Container padding: `18px 24px 20px`
- Status pill margin from top: `18px`
- Previous line margin-top: `28px`, margin-bottom: `16px`
- Current line margin-top from previous: `16px`
- Floating bar inset: `16px` all sides at bottom
- Floating bar padding: `10px 12px`

---

## Tokens (use existing app design tokens; reference values)

```
bg            #1a1612           Page background
surface       #2a231d           Status pill, settings sheet
surfaceHi     #332b23           Hover/elevated
ink           #f5ede0           Primary text
inkSoft       rgba(245,237,224,0.72)   Secondary text
inkMute       rgba(245,237,224,0.45)   Tertiary text
inkDim        rgba(245,237,224,0.22)   Previous/silenced line, hints
line          rgba(245,237,224,0.08)   Hairlines
lineHi        rgba(245,237,224,0.16)   Bar borders

peach         #e89878           Accent (caret, pause button, breathing dot)
peachSoft     rgba(232,152,120,0.18)   Selected toggle bg

fontDisplay   "Fraunces", "Iowan Old Style", Georgia, serif
fontUI        "Inter", -apple-system, system-ui, sans-serif
```

---

## Components

### Status pill (always visible)
- 4 animated waveform bars, 2.5px wide, 4–10px tall, peach, scale-Y animation (0.5 → 1.4 → 0.5) staggered 0.07s per bar
- Label: `Listening · {HH:MM:SS}` in tabular-nums
- Pill: surface bg, 6×12 padding, 999 border-radius
- Position: top-left, inline with container padding

### Right-margin sound tag (B2)
- Absolute positioned, top: 22px, right: 24px
- 11px uppercase, letter-spacing 1px, weight 700
- color: inkMute
- Format: `[icon] LABEL` (e.g. ♫ JAZZ, 💬 LAUGHTER)
- Visible only when ambient sound is present and "Show ambient sounds" is on
- Cycles through detected sounds — show the loudest/most recent

### Caption stack
- **Previous line**: fontDisplay, 20px, line-height 1.3, color inkDim
- **Current line**: fontDisplay, 32px, weight 500, line-height 1.2, letter-spacing -0.8px, color ink
- **Caret**: 3px wide × 26px tall, peach, blinks at 50% steps every 1s

### Floating bar (transient)
- Position: absolute, left/right 16px, bottom 16px
- Background: `rgba(42,35,29,0.92)` + `backdrop-filter: blur(20px)`
- Border: 1px solid `lineHi`
- Border-radius: 28px
- Box-shadow: `0 12px 32px rgba(0,0,0,0.4)`
- Contents (left to right): cog button · star button · spacer · pause button
- Cog/star: 40×40, transparent bg, inkSoft icon
- Pause: 44×44, peach bg, bg-color icon
- Transitions: transform 0.25s cubic-bezier(0.2,0.8,0.2,1), opacity 0.2s
- Hidden state: `translateY(90px)` + opacity 0

### Quick settings bottom sheet
- Backdrop: `rgba(0,0,0,0.5)` + `backdrop-filter: blur(4px)`
- Sheet: anchored to bottom, surface bg, top-corners 22px radius, border-top
- Header: grabber (38×4, lineHi), title "Adjust" (fontDisplay 19px weight 600), close button
- Rows separated by `1px solid line`:
  - **Text size**: segmented A/A/A/A pill with peach selection, values: small / regular / large / huge
  - **Show ambient sounds**: switch (peach on, line off)
  - **Vibrate on alerts**: switch with sub-label "Smoke alarm, doorbell, baby crying"
  - **All settings →**: link to deep settings screen

---

## Interaction rules

1. **Tap anywhere on captions area** → reveal floating bar; reset 3000ms auto-hide timer.
2. **Tap floating bar** → does NOT auto-hide (stops propagation).
3. **Tap cog** → open settings sheet; auto-hide is suspended while sheet open.
4. **Tap star** → save current moment with toast feedback (use existing save flow).
5. **Tap pause** → stop transcription, go to end-of-conversation save flow.
6. **Tap backdrop or close (×) or grabber** → dismiss settings sheet, resume auto-hide.
7. **No speech for 5s** → enter silence state. Last line dims to 22%. Show "N seconds of silence" pill.
8. **Speech resumes** → silence pill animates out; new line fades in.
9. **Sound detected** → margin tag updates with smooth crossfade (300ms).
10. **Urgent sound** (smoke alarm, baby crying, doorbell) → does NOT use margin tag. Use the existing full-bleed alert hero from the Spotlight app.

---

## States to test
- [ ] First sentence — no previous line
- [ ] Multi-line current sentence
- [ ] Speaker change mid-sentence
- [ ] Silence (5s, 30s, 2min)
- [ ] Ambient sound on/off
- [ ] Margin tag with longer label (e.g. "DISHES")
- [ ] Settings sheet with reduced motion / large text accessibility settings
- [ ] RTL languages

---

## Handing off to Claude Code

### 1. Open your Android repo in Claude Code

```bash
cd path/to/live-transcribe-android
claude
```

### 2. Share the spec file

```bash
# From this design project, download captions-rev2.jsx and this README,
# then drop them somewhere Claude Code can read them:
mkdir -p docs/design
mv ~/Downloads/captions-rev2.jsx docs/design/
mv ~/Downloads/CAPTIONS_HANDOFF.md docs/design/
```

### 3. Prompt

> Read `docs/design/CAPTIONS_HANDOFF.md` and `docs/design/captions-rev2.jsx`. Implement the captions screen described there as a Jetpack Compose screen (or [your stack]). The JSX file is a reference React implementation — you don't need to port it 1:1, but match the layout, tokens, interactions, and animation timings exactly. The status pill, current/previous line typography, floating bar reveal/hide, settings sheet, and silence state are all required. Reuse our existing design tokens (`Tokens.kt` or whatever lives in your repo) where they map to the ones in the spec. Output the Compose file plus any helper components, with brief comments noting which spec section each block implements.

### 4. After the first pass

Ask Claude Code to verify:
- Tap-to-reveal timer is exactly 3000ms; tap on bar does not reset
- Status pill stays visible across all states
- Silence pill appears at exactly 5s of no detected speech
- Settings sheet honors system Reduce Motion
- Caret pulse pauses when "Reduce Motion" is on
- Text-size segmented control respects system fontScale ceiling

### 5. If you have a designer/eng review loop

The reference file (`captions-rev2.jsx`) renders interactively in a browser — share the URL with the eng team for visual sign-off before implementation. They can tap to see the bar reveal in real-time motion.

---

## Files in this handoff

```
docs/design/
├── CAPTIONS_HANDOFF.md       (this file)
└── captions-rev2.jsx         (reference React implementation, viewable in browser)
```
