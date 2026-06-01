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

**RECOMMENDED (heritage hook, de-named for Guideline 2.3.10):**

```
Free, private, on-device captions — built by an accessibility PM. 99 languages, translate to English, ambient-sound alerts. No ads, no cloud, no sign-up.
```
(153 chars — Apple counts em-dash as one char.)

NOTE on 2.3.10: an earlier version named Android / Google Live Transcribe directly as the
"heritage hook" — that triggered a Guideline 2.3.10 (Accurate Metadata) rejection because
Apple does not allow naming other mobile platforms in App Store listing copy. The
de-named phrasing above keeps the credibility angle without naming a competing platform.

Alternatives:

```
Truly free, fully private captions that run on your iPhone. 99 languages, translate to English, 300 ambient sounds. Accessibility shouldn't cost money or privacy.
```
(162 chars — mission angle)

```
Captions in real time, on your phone. No accounts, no cloud, no tracking. Translate other languages to English on the fly. Built for the deaf and hard-of-hearing.
```
(167 chars — original, feature angle)

NOTE: Promotional Text is updatable any time without re-review, so it's the right place for
timely messaging — but keep "beta" / "DM me for early access" wording OUT of it and the
Description (Apple guideline 2.2 rejects beta/demo framing on the public store). Save that for
TestFlight "What to Test".

## Description (4000 char max)

```
Earshot is real-time, on-device captioning for iPhone — for conversations, lectures, doctor visits, anywhere you want to read what's being said.

A bit of backstory. Earlier in my career, I was one of two product managers on a free, real-time captioning app for the deaf and hard-of-hearing — inspired by a Deaf researcher who'd spent his career on captioning. It became one of the most-adopted accessibility apps I've ever worked on and reached hundreds of millions of people.

Nothing equivalent has shipped on iPhone. The captioning apps that are available are useful, but few are genuinely free, private, and multilingual all at once — many charge, upsell, or send your audio to the cloud. Having a disability shouldn't cost you money or your privacy. So I built Earshot.

• Free — no sign-up, no sign-in, no ads, no upsells.
• Private — everything runs on your device. The only network call is to download and update the local speech model (OpenAI's Whisper).
• Offline — works with no Wi-Fi or cellular connection.
• Multilingual — 99 languages, and it can translate any of them into English.
• Ambient-sound aware — recognizes hundreds of environmental sounds, with full-screen alerts for urgent ones: smoke alarm, carbon monoxide, doorbell, crying baby, phone ringing, sirens.

All speech recognition runs locally with OpenAI's Whisper. Word Error Rate — the standard accuracy benchmark — is about 8.6% for the "small" English model; it runs higher for other languages, especially long-tail ones. Earshot also ships the tiny and base models, which are blazingly fast and work well on older iPhones — in testing they held up on accuracy too.

Accessibility tools shouldn't themselves be inaccessible. Free should mean free. Private should mean private. iPhone users deserve that standard too.

WHAT IT DOES
• Real-time captions in a clean, focused screen, plus a chat-style "feed" layout. Tap the cog for text size, vibration, and ambient-sound options.
• Translate non-English speech to English on the fly.
• Full-screen urgent-sound alerts with strong haptics; ambient-sound tags shown in the corner when you want them.
• Save transcripts on your device as readable documents. Star the ones to keep, filter by 1:1 or group, by alerts, by starred.
• Share any transcript as plain text — it never leaves your device unless you send it.
• Full Dynamic Type up to AX5, VoiceOver labels on every control, Reduce Motion honored.

WHO IT'S FOR
Built for the deaf and hard-of-hearing community as a private alternative to cloud captioning. Also useful in loud environments, for language learners, and for anyone who wants to read or save what was said.

PRIVACY
Audio never leaves your device. No accounts, no analytics, no ads, no tracking. The Whisper model downloads once on first launch (~244 MB) — the only network request the app makes. Full policy at briankemler.github.io/LiveTranscribe/privacy.

REQUIREMENTS
iPhone on iOS 17 or later. Works offline after the one-time model download.

CONTACT
brian.kemler@gmail.com
```
(~3235 chars; room to spare under the 4000 limit)

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

Notes for the reviewer — paste into App Review → Notes (plain text; under the 4,000-char
limit). Written to preempt the likely review questions: the first-launch network download
and the safety-sound feature.

```
RESUBMISSION — RESPONSE TO PREVIOUS REJECTION (Guideline 5.1.1(iv), build 33)
The previous build's onboarding privacy screen used a button labeled "Allow microphone" before the system permission prompt. Per your guidance, that button is now labeled "Continue" — it no longer uses wording that pre-empts the permission decision. The screen explains why the microphone is used; the actual Allow/Don't Allow choice is made entirely in the iOS system prompt that follows. No other permission-priming buttons in the app use directive wording.
(The prior Guideline 2.1 issue — a misleading "microphone unavailable" message caused by an interrupted model download — was resolved in build 32: the on-device model now self-repairs incomplete downloads, and model errors are reported accurately with a Retry action, never as a microphone problem.)

ABOUT EARSHOT
Earshot is a real-time, on-device live-captioning and sound-recognition app for the deaf and hard-of-hearing (and anyone who wants to read along). It captions nearby speech, can translate 99 languages into English, and recognizes environmental sounds (e.g., smoke alarm, doorbell) with on-screen alerts.

NO ACCOUNT OR LOGIN NEEDED
There is no sign-in, no account, and no paywall — just launch and use. The app is free with no in-app purchases, so there is nothing to provide a demo account for.

ALL PROCESSING IS ON-DEVICE
- Speech recognition: OpenAI Whisper, run locally via the open-source WhisperKit framework (MIT, github.com/argmaxinc/WhisperKit).
- Sound classification: Apple's built-in SoundAnalysis framework (SNClassifySoundRequest, classifierIdentifier .version1).
There is no server-side component. Audio is processed in memory and never written to disk or transmitted.

THE ONE NETWORK REQUEST (please note)
On first launch — and only then — the app downloads the Whisper speech model (~244 MB) from Hugging Face (huggingface.co). This is the single network request the app makes. It needs Wi-Fi or cellular and can take a minute or two on first run. After the model is cached, the app works fully offline. A "Downloading on-device model…" progress screen on first launch is expected.

MICROPHONE PERMISSION
Requested with: "Earshot uses the microphone on this device to caption nearby speech and recognize sounds. Audio is processed entirely on-device and never leaves your phone." Required for captioning and sound recognition; if denied, the app degrades gracefully and points the user to Settings.

HOW TO TEST
1. Launch the app and complete the brief onboarding; tap "Continue" on the privacy screen, then choose Allow in the iOS microphone prompt.
2. On first launch, wait for the Whisper model to finish downloading (needs a network connection; ~244 MB).
3. From Home, tap "Start listening."
4. Speak near the device — captions appear in real time. Please test on a physical device: the iOS Simulator does not capture microphone input, so captions will not populate there.
5. Optional: Settings > Captions > Language > Output toggles translate-to-English.
6. Optional: Settings > Sounds arms urgent-sound alerts (e.g., smoke alarm).

APP NAME
The App Store listing name is "Earshot Live Transcription." The Home-screen icon label (CFBundleDisplayName) is the shorter "Earshot." Both refer to the same app.

SOUND ALERTS ARE ASSISTIVE, NOT A CERTIFIED SAFETY DEVICE
The urgent-sound alerts (smoke alarm, carbon monoxide, etc.) are a best-effort assistive feature, not a substitute for certified alarms or medical/safety equipment. The app makes no medical claims.

PRIVACY & COMPLIANCE
- No data collection, no analytics, no ads, no tracking, no data-exfiltrating third-party SDKs.
- PrivacyInfo.xcprivacy is bundled; NSPrivacyCollectedDataTypes is empty; required-reason API usage (UserDefaults) is declared.
- ITSAppUsesNonExemptEncryption is NO; no export-compliance documentation required.
- iPhone only; iOS 17 and later.

CONTACT
Questions during review: brian.kemler@gmail.com — happy to respond quickly.
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
