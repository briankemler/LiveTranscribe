# App Store screenshots — Earshot

One folder per App Store Connect upload slot. Each holds the same 8 screens (below), all
**native captures at the exact accepted resolution** — no rescaling, so text stays sharp.

| Folder        | Pixels      | Device captured on            | App Store Connect slot |
|---------------|-------------|-------------------------------|------------------------|
| `6.9-inch/`   | 1320 × 2868 | iPhone 17 Pro Max (iOS 26)    | **6.9" Display** |
| `6.5-inch/`   | 1242 × 2688 | iPhone 11 Pro Max (iOS 18)    | **6.5" Display** |
| `6.3-inch/`   | 1206 × 2622 | iPhone 16 Pro (iOS 18)        | **6.3" Display** |
| `6.1-inch/`   | 1179 × 2556 | iPhone 16 (iOS 18)            | **6.1" Display** |
| `4.7-inch/`   |  750 × 1334 | iPhone SE 3rd gen (iOS 18)    | **4.7" Display** |

**You only NEED the largest (6.9").** Every other slot is optional — if left empty, Apple
auto-scales your 6.9" screenshots to fill it. These extra folders are provided for pixel-perfect
coverage if you'd rather not rely on Apple's scaling.

**Slots deliberately NOT provided — 5.5", 4", 3.5":** those are iPhone 8 Plus / SE-1 / 4s-era
devices that can't run iOS 17 (the app's minimum), so the app can't launch on them to capture
natively, and down-scaling distorts (they're 16:9 / 4:3, not the tall modern aspect). Leave
those slots empty; Apple scales the larger screenshots for them.

## What's here

Captured from **build 23** (the Earshot rename) in **Warm palette + dark appearance** via the
`--route` launch arg. Suggested App Store carousel order:

| File                        | Route / arg                   | Why this screen |
|-----------------------------|-------------------------------|---|
| `00_captions.png`           | `live11 --demo-captions`      | **The hero.** Populated live-captions screen — what the app actually does. First in the carousel. |
| `01_onboarding.png`         | `onboarding1`                 | Brand hero — "EARSHOT · Every voice. Every sound. Fast, free and private captions." |
| `02_home.png`               | `home`                        | Landing page; "Ready when you are." Communicates the core action. |
| `03_alert.png`              | `alert`                       | Safety-sound feature in action: a 96%-match smoke-alarm alert over live captions. |
| `04_sound_detection.png`    | `soundSettings`               | The sound catalog — breadth of detectable sounds + the "up to 6 urgent" picker. |
| `05_settings.png`           | `settings`                    | "Make it yours." Feature surface + privacy controls. |
| `06_acknowledgements.png`   | `acknowledgements`            | Credibility — open-source provenance (WhisperKit, Whisper, SoundAnalysis). |
| `07_privacy.png`            | `privacyPolicy`               | Privacy-forward stance: "Earshot processes audio entirely on your iPhone." |

Apple requires 3 screenshots minimum, allows up to 10. Eight is comfortable.

## The captions hero (`00_captions.png`) — how it's made

The live-captions screen can't be captured the normal way on the Simulator: the iOS Simulator
on Apple Silicon doesn't capture the mic, so the caption stack never populates (it sits on
"Compiling for Neural Engine" / "Listening…"). Instead there's a **Debug-only** launch arg,
`--demo-captions`, that seeds the caption slots with scripted lines and skips the real
mic + model pipeline. It's gated behind `#if DEBUG` (see `LiveSession.seedDemoCaptions` and
`CaptionsView.task`), so it's compiled out of the App Store (Release) build entirely.

If you'd prefer a genuine real-device capture instead: install a TestFlight build on an iPhone
Pro Max, tap Start listening, accept the mic prompt, wait for Whisper to download, have someone
talk, then side-button + volume-up. Drop the PNG in as `00_captions.png`.

## Regenerating the Simulator screens

Pick the device for the size you want (the Debug `.app` installs on any of them):
- **6.9" / 1320×2868:** iPhone 17 Pro Max, e.g. `DB771742-7FAF-4283-9E80-CCE95B4BC433` → `OUT=6.9-inch`
- **6.5" / 1242×2688:** iPhone 11 Pro Max on iOS 18, create with
  `xcrun simctl create Earshot-65 com.apple.CoreSimulator.SimDeviceType.iPhone-11-Pro-Max com.apple.CoreSimulator.SimRuntime.iOS-18-4` → `OUT=6.5-inch`

```bash
DEV=<udid-from-above>
OUT=6.9-inch                                     # or 6.5-inch
BID=com.briankemler.LiveTranscribe
APP=./DerivedData/Build/Products/Debug-iphonesimulator/LiveTranscribe.app

xcrun simctl bootstatus "$DEV" -b
xcrun simctl ui "$DEV" appearance dark
xcrun simctl install "$DEV" "$APP"

cap () {  # file  extra-args...
  local file=$1; shift
  xcrun simctl terminate "$DEV" "$BID" 2>/dev/null
  xcrun simctl launch "$DEV" "$BID" --palette warm "$@"
  sleep 3
  xcrun simctl io "$DEV" screenshot "AppStoreScreenshots/$OUT/$file"
}
cap 00_captions.png        --route live11 --demo-captions
cap 01_onboarding.png      --route onboarding1
cap 02_home.png            --route home
cap 03_alert.png           --route alert
cap 04_sound_detection.png --route soundSettings
cap 05_settings.png        --route settings
cap 06_acknowledgements.png --route acknowledgements
cap 07_privacy.png         --route privacyPolicy
```

The `AppStoreMetadata.md` doc in the project root has the marketing copy that goes with
these screenshots — paste it into App Store Connect alongside the uploads.
