# App Store Connect metadata — Earshot

Paste these fields into App Store Connect → My Apps → Earshot → App Store tab.

---

## Name (30 char max)

```
Earshot Live Transcription
```
(26 chars — the exact name registered in App Store Connect; plain "Earshot" was taken.
NOTE: the App Store **listing name** is "Earshot Live Transcription", but the Home-screen
icon label, set by `CFBundleDisplayName`, is just "Earshot" — these are allowed to differ.)

## Subtitle (30 char max)

```
On-device live captions
```
(23 chars)

Alternative subtitles to A/B if 23 feels generic:

- `Real-time captions, private.` (28)
- `Captions that stay on your phone` (32 — too long)
- `Live captions. No cloud.` (24)

## Promotional Text (170 char max, updatable any time)

```
Captions in real time, on your phone. No accounts, no cloud, no tracking. Translate other languages to English on the fly. Built for the deaf and hard-of-hearing.
```
(167 chars)

## Description (4000 char max)

```
Earshot turns your iPhone into a real-time caption machine — for conversations, lectures, doctor visits, anywhere you want to read along.

Everything runs on your phone. The Whisper Small speech-recognition model and Apple's sound classifier live inside the app. Your audio is never sent to a server, never logged, never stored. There are no accounts, no analytics, no ads.

WHAT IT DOES
• Real-time captions in a clean, focused screen. Tap the cog for quick text-size, vibration, and ambient-sound options.
• Translate non-English speech to English on the fly. Whisper supports 99 source languages.
• Smoke-alarm, doorbell, baby-crying, carbon-monoxide, phone-ringing, and emergency-siren alerts. Full-screen with strong haptic.
• Ambient sound tags (laughter, music, water running, dog barking, and 25+ more) shown in the corner when you want them.
• Save transcripts on your device. Star the ones you want to find later. Search, filter by 1:1 or group, by alerts, by starred.
• Share any transcript as plain text — Notes, Files, Mail, Messages, anything that accepts text. The share never leaves your device unless you send it.
• Full Dynamic Type support up to AX5. VoiceOver labels on every interactive element. Reduce-Motion honored.

WHO IT'S FOR
Earshot was built for the deaf and hard-of-hearing community as a practical, private alternative to cloud-based captioning. It is also useful for:
• Anyone in a loud environment (cafés, conferences, noisy kitchens) who wants visual reinforcement of conversations.
• Language learners who want translations of native-speaker dialogue.
• People who want to skim or save what someone said without explaining "I'm recording you."

PRIVACY
The app's headline guarantee: audio never leaves your device. The Whisper model itself downloads once from Hugging Face on first launch (~244 MB) — that download is the only network request the app makes. Everything after that is offline.

Full privacy policy in Settings → About → Privacy Policy, also published at briankemler.github.io/LiveTranscribe/privacy.

PERMISSIONS
Microphone — required for transcription and sound recognition. You can grant or revoke at any time in iOS Settings.

REQUIREMENTS
iPhone running iOS 17 or later. iPhone 12 or newer recommended for real-time performance. ~250 MB free disk space for the speech model.

CONTACT
brian.kemler@gmail.com
```
(~1900 chars; room to grow)

## Keywords (100 char max, comma-separated)

**RECOMMENDED — use this set:**

```
hearing,deaf,accessibility,subtitles,speech,offline,private,translate,dictation,whisper,sound
```
(93 chars)

Why this set: the App Store already indexes the app **Name** ("Earshot Live Transcription")
and **Subtitle** ("On-device live captions"), so anything already in those is wasted in the
keyword field. That rules out `earshot`, `live`, `transcription`, `transcribe` (same stem as
"transcription"), `captions`, and `on-device` — all already searchable. This set spends the
100 chars on terms that AREN'T in the name/subtitle: the audience (`hearing`, `deaf`,
`accessibility`), the feature surface (`subtitles`, `speech`, `translate`, `dictation`,
`sound`), the privacy angle (`offline`, `private`), and the tech (`whisper`). Don't add spaces
after commas — Apple counts each space against your 100.

## Support URL

```
https://briankemler.github.io/LiveTranscribe/privacy/
```

(Hosted on GitHub Pages from the `docs/` folder of the briankemler/LiveTranscribe repo. The
landing page at `https://briankemler.github.io/LiveTranscribe/` also works as a Support URL —
it carries the contact email and links to the policy. Must be live before submitting for
review: create the repo, push, enable Pages.)

**App Privacy Policy URL field** (App Information → also required separately from Support URL):

```
https://briankemler.github.io/LiveTranscribe/privacy/
```

## Marketing URL (optional)

Leave blank for now or use the same as Support.

## App Category

Primary: **Productivity** OR **Utilities**
- "Productivity" maps best to use-cases like note-taking conversations.
- "Utilities" maps to tools/services like flashlight, calculator.
- Recommendation: **Productivity** primary, **Health & Fitness** or **Utilities** secondary.

(Cannot pick "Medical" without medical-device positioning. "Lifestyle" is too vague.)

## Age Rating

The App Store age questionnaire — recommended answers:

- All categories: **None**.
- The app contains: no profanity, no horror, no realistic violence, no sexual content, no mature themes, no gambling, no medical/treatment info, no alcohol/tobacco/drugs.
- Result: rated **4+**.

## App Review Information

Notes for the reviewer — paste into App Review → Notes:

```
Earshot processes audio entirely on-device using:
• OpenAI Whisper Small (speech recognition) via the WhisperKit framework (MIT, github.com/argmaxinc/WhisperKit)
• Apple SoundAnalysis (urgent and ambient sound classification, built-in iOS framework)

On first launch, the app downloads the Whisper model (~244 MB) from Hugging Face. This is the only network request the app makes. After download, the app works fully offline.

The app requests microphone permission with the description "Earshot uses the microphone on this device to caption nearby speech and recognize sounds. Audio is processed entirely on-device and never leaves your phone."

No login required. No analytics. The app has no server-side component.

PrivacyInfo.xcprivacy is bundled and declares the required-reason API usage.

To test:
1. Allow microphone permission on first run.
2. Wait for the Whisper Small model to download (~244 MB; needs Wi-Fi or cellular).
3. From Home, tap "Start listening" to start a captioning session.
4. Speak nearby — captions appear in real time.
5. Settings → Sounds → Sound detection lets you arm urgent sounds.
6. Settings → Captions → Language → Output toggles English-translation mode.
```

## What's New (for each release)

Currently in `TestFlightNotes.md` — for App Store submission, take the most recent build's "What's new since…" section.

## Privacy Manifest

Already bundled at `Resources/PrivacyInfo.xcprivacy`. Declares:
- `NSPrivacyCollectedDataTypes`: empty (we collect nothing)
- Required-reason API usage (UserDefaults)

## Encryption export compliance

`ITSAppUsesNonExemptEncryption` is already `NO` in Info.plist. No further export-compliance documentation needed.

## Pricing

- **Free** (no IAP, no subscription, no paid tier).
- Available in all territories.
