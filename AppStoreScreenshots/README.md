# App Store screenshots — Live Transcribe

PNG files in this folder are iPhone 17 Pro Max captures at **1320 × 2868 px** — Apple's
required 6.9" iPhone screenshot size.

## What's here

Five screens, all in **Warm palette + dark appearance**, captured from build 16 via the
`--route` launch arg. Order is the App Store carousel order:

| File                          | Route             | Why this screen |
|-------------------------------|-------------------|---|
| `02_home.png`                 | `home`            | Landing page; "Ready when you are" — communicates the app's brand. |
| `03_alert.png`                | `alert`           | The safety-sound feature in action: smoke alarm alert. |
| `04_sound_detection.png`      | `soundSettings`   | The build-16 sound catalog showing breadth + selectability. |
| `05_settings.png`             | `settings`        | Reinforces privacy stance + feature surface. |
| `06_acknowledgements.png`     | `acknowledgements`| Credibility — open-source provenance. |

Apple requires 3 screenshots minimum, allows up to 10. Five is comfortable.

## Missing: 01_captions.png (the captions hero shot)

The Live captions screen needs the microphone permission dialog dismissed to render cleanly,
and on the iOS Simulator the mic prompt **always** shows on first run (`simctl privacy grant
microphone` is a known no-op for iOS sims). Easiest paths to capture it:

### Option A — capture on a real iPhone (best result)
1. Install the latest TestFlight build on an iPhone Pro Max (6.9" — 14 Pro Max, 15 Pro Max,
   16 Pro Max, or 17 Pro Max).
2. Open the app, tap Start listening, accept the mic prompt, wait for Whisper to download.
3. Have someone say a sentence or two so the caption stack populates.
4. Screenshot: side button + volume up.
5. Drop the PNG into this folder as `01_captions.png` — it'll already be the right
   resolution from a Pro Max device.

### Option B — capture on the Simulator with manual mic-prompt dismissal
1. Boot the iPhone 17 Pro Max simulator and install the Debug build:
   ```bash
   xcrun simctl boot DB771742-7FAF-4283-9E80-CCE95B4BC433
   xcrun simctl install booted ./DerivedData-ProMax/Build/Products/Debug-iphonesimulator/LiveTranscribe.app
   ```
2. Open the Simulator app: `open -a Simulator`
3. Launch the app to the captions route:
   ```bash
   xcrun simctl launch booted com.briankemler.LiveTranscribe --route live11
   ```
4. **Manually click "Allow"** in the simulator window when the mic prompt appears.
5. Wait for the Whisper model to download (~244 MB; sim shows progress in the caption text).
6. Once the placeholder reads "Listening…" or actual content is showing, screenshot:
   ```bash
   xcrun simctl io booted screenshot AppStoreScreenshots/01_captions.png
   ```

## Regenerating the other five

The five existing screenshots can be regenerated any time:
```bash
DEVICE=DB771742-7FAF-4283-9E80-CCE95B4BC433
xcrun simctl erase "$DEVICE" && xcrun simctl boot "$DEVICE" && sleep 6
xcrun simctl ui "$DEVICE" appearance dark
xcrun simctl install "$DEVICE" ./DerivedData-ProMax/Build/Products/Debug-iphonesimulator/LiveTranscribe.app

# Then loop through routes — see the bash one-liner used in build 16.
```

The `AppStoreMetadata.md` doc in the project root has the marketing copy that goes with
these screenshots — paste it into App Store Connect alongside the uploads.
