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

**RECOMMENDED (heritage hook):**

```
Free, private, on-device captions — by a PM behind Android's Live Transcribe. 99 languages, translate to English, ambient-sound alerts. No ads, no cloud, no sign-up.
```
(167 chars)

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

A bit of backstory. In 2019, a team at Google spent nine months building Android's Live Transcribe — a free app that captions speech and ambient sound in real time, inspired by a Deaf researcher who'd spent his career on captioning. It launched at Google I/O, became one of the most-adopted accessibility apps Google ever shipped, and came preloaded on billions of Android devices. I was one of two product managers on it.

Google never shipped Live Transcribe on iOS, and nothing has truly filled the gap. There are lookalikes, but few are genuinely free, private, and multilingual all at once — many charge, upsell, or send your audio to the cloud. Having a disability shouldn't cost you money or your privacy. So I built Earshot.

• Free — no sign-up, no sign-in, no ads, no upsells.
• Private — everything runs on your device. The only network call is to download and update the local speech model (OpenAI's Whisper).
• Offline — works with no Wi-Fi or cellular connection.
• Multilingual — 99 languages, and it can translate any of them into English.
• Ambient-sound aware — recognizes hundreds of environmental sounds, with full-screen alerts for urgent ones: smoke alarm, carbon monoxide, doorbell, crying baby, phone ringing, sirens.

All speech recognition runs locally with OpenAI's Whisper. Word Error Rate — the standard accuracy benchmark — is about 8.6% for the "small" English model; it runs higher for other languages, especially long-tail ones. Earshot also ships the tiny and base models, which are blazingly fast and work well on older iPhones — in testing they held up on accuracy too.

Accessibility tools shouldn't themselves be inaccessible. Free should mean free. Private should mean private. That's the standard the original Live Transcribe set on Android, and iOS users deserve the same.

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
