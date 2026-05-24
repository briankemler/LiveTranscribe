# App Store screenshots — Earshot

PNG files in this folder are iPhone 17 Pro Max captures at **1320 × 2868 px** — Apple's
required 6.9" iPhone screenshot size. Upload them to the **6.9" Display** slot in App Store
Connect; Apple auto-scales them down for smaller devices, so no separate 6.5" set is needed.

## What's here

Captured from **build 23** (the Earshot rename) in **Warm palette + dark appearance** via the
`--route` launch arg. Suggested App Store carousel order:

| File                        | Route             | Why this screen |
|-----------------------------|-------------------|---|
| `01_onboarding.png`         | `onboarding1`     | Brand hero — "EARSHOT · Every voice. Every sound. Fast, free and private captions." |
| `02_home.png`               | `home`            | Landing page; "Ready when you are." Communicates the core action. |
| `03_alert.png`              | `alert`           | Safety-sound feature in action: a 96%-match smoke-alarm alert over live captions. |
| `04_sound_detection.png`    | `soundSettings`   | The sound catalog — breadth of detectable sounds + the "up to 6 urgent" picker. |
| `05_settings.png`           | `settings`        | "Make it yours." Feature surface + privacy controls. |
| `06_acknowledgements.png`   | `acknowledgements`| Credibility — open-source provenance (WhisperKit, Whisper, SoundAnalysis). |
| `07_privacy.png`            | `privacyPolicy`   | Privacy-forward stance: "Earshot processes audio entirely on your iPhone." |

Apple requires 3 screenshots minimum, allows up to 10. Seven is comfortable.

## Still missing: the captions hero (`00_captions.png`)

The core feature — a populated live-captions screen — **cannot be captured on the Simulator**:
the iOS Simulator on Apple Silicon doesn't capture the mic, so the caption stack never
populates (it sits on "Compiling for Neural Engine" / "Listening…"). This needs a real device.

**It should be the FIRST screenshot in the carousel** (the install sheet shows the first 3),
since it's what the app actually does. Capture it on a real iPhone:

1. Install the latest TestFlight build (build 23+) on an iPhone Pro Max (6.9" — 14/15/16/17
   Pro Max).
2. Open Earshot, tap **Start listening**, accept the mic prompt, wait for Whisper to download.
3. Have someone say a couple of sentences so the caption stack populates.
4. Screenshot: side button + volume up.
5. Drop the PNG into this folder as `00_captions.png` — it's already the right resolution
   from a Pro Max device.

## Regenerating the seven Simulator screens

```bash
DEV=DB771742-7FAF-4283-9E80-CCE95B4BC433        # iPhone 17 Pro Max (1320×2868)
BID=com.briankemler.LiveTranscribe
APP=./DerivedData/Build/Products/Debug-iphonesimulator/LiveTranscribe.app

xcrun simctl boot "$DEV"; xcrun simctl bootstatus "$DEV" -b
xcrun simctl ui "$DEV" appearance dark
xcrun simctl install "$DEV" "$APP"

cap () {  # route file
  xcrun simctl terminate "$DEV" "$BID" 2>/dev/null
  xcrun simctl launch "$DEV" "$BID" --route "$1" --palette warm
  sleep 3
  xcrun simctl io "$DEV" screenshot "AppStoreScreenshots/$2"
}
cap onboarding1 01_onboarding.png
cap home 02_home.png
cap alert 03_alert.png
cap soundSettings 04_sound_detection.png
cap settings 05_settings.png
cap acknowledgements 06_acknowledgements.png
cap privacyPolicy 07_privacy.png
```

The `AppStoreMetadata.md` doc in the project root has the marketing copy that goes with
these screenshots — paste it into App Store Connect alongside the uploads.
