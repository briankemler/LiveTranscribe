# Real-device verification checklist (build 17 prep)

Build 16 added ~25 new non-urgent classifier IDs that are best-guess against Apple's
`SNClassifySoundRequest(.version1)` set. The iOS Simulator's classifier matches the host
macOS version, not the deployment target, so we can't reliably verify on the sim. This
checklist walks the things that need a physical iPhone in hand to confirm.

## What you need

- Physical iPhone running iOS 17+ (any model; mic capture is what matters).
- Build 16 (or later) installed via TestFlight.

## Sound classifier ID verification (highest priority)

We hardcode classifier IDs in `Sources/Models/SoundCatalog.swift`. If any of these aren't
in Apple's actual `version1` set on this iOS version, that chip is dead — selectable but
no detection will fire.

### Steps
1. Open the app → Settings → Developer → Sound classifier.
2. Look at the top of the screen for a red banner labeled **"MISSING FROM THIS iOS"**. If
   the banner is present, every line under it is a classifier ID we hardcoded that doesn't
   exist on your iOS.
3. Note any IDs flagged red. The display format is `• Label → classifier_id`.

### IDs I'd specifically worry about

These are the build-16 additions that I have lower confidence in. Apple's full label list
isn't published as a manifest; we're going on dev forum posts + Apple sample code.

| Chip                | Classifier ID I used         | Confidence |
|---------------------|------------------------------|------------|
| Emergency sirens    | `fire_engine_siren_horn`     | Medium     |
| Emergency sirens    | `police_siren`               | Medium     |
| Emergency sirens    | `ambulance_siren`            | Medium     |
| Footsteps           | `walk_footsteps`             | **Low**    |
| Motorcycle          | `motorcycle`                 | Medium     |
| Acoustic guitar     | `acoustic_guitar`            | Medium     |
| Piano               | `piano`                      | Medium     |
| Drums               | `drum_kit_drumming`          | Medium     |
| Sink running        | `sink_filling_with_liquid`   | **Low**    |
| Hair dryer          | `hair_dryer`                 | Medium     |
| Sneeze              | `sneeze`                     | Medium     |
| Toilet flush        | `toilet_flush`               | Medium     |

Tell me which IDs the banner lists, and I'll swap them for the correct identifiers in
build 17 and re-verify.

## Dynamic Type pass at AX5 (medium priority)

The build-11 Dynamic Type sweep should hold up to AX5 on a small phone. Test on an iPhone
SE if you have one (no Pro Max — Pro Max masks layout issues with extra width).

### Steps
1. iOS Settings → Accessibility → Display & Text Size → Larger Text → on, drag to the
   rightmost notch (AX5).
2. Walk every screen in the app:
   - Onboarding (use `--reset-onboarding` if needed; or delete + reinstall)
   - Home
   - Captions (1:1)
   - Settings → all sub-screens
   - Summary (after a brief Live session)
   - History (Transcripts → Saved conversations → row)
3. Watch for:
   - Truncated text mid-sentence
   - Headlines that push primary controls off-screen
   - Buttons whose tap targets shrink
   - Caption text on the Live screen pushing the floating bar past the bottom edge

Report any truncation / overlap with the screen name and (rough) screenshot if possible.

## VoiceOver pass (medium priority)

### Steps
1. iOS Settings → Accessibility → VoiceOver → on. (Triple-click side button is the system
   shortcut to toggle.)
2. Walk the same screens. Use rotor (two-finger twist) to swipe between elements.
3. Watch for:
   - Buttons that announce as "chevron left" instead of meaningful labels like "Back"
   - Transcript caption lines reading as separate "MAYA", "0:42", text fragments instead
     of one combined "Maya, 0:42, …"
   - Live captions on the Live screen not announcing as new lines land (build 11 added
     auto-announcements; verify on real audio)
   - Alert screen (smoke alarm) doesn't trap focus / can be swiped past

## Real audio: smoke-alarm sample (low priority but cool)

If you have a phone, smartwatch, or smart speaker that can play a smoke-alarm sound effect
nearby, the urgent path is worth a one-time confirmation:

### Steps
1. Open the app → start a 1:1 Live session.
2. Play a smoke-alarm sound from another device near the mic. YouTube has plenty of clips.
3. The app should:
   - Fire the full-screen AlertView with "Smoke alarm" hero text.
   - Buzz with a strong error haptic (unless you toggled "Vibrate on alerts" off).
   - Auto-announce via VoiceOver if running.

If it doesn't fire, the classifier ID `smoke_detector_smoke_alarm` may be different on
your iOS. The Sound Diagnostics screen will tell you.

## Translate-to-English path (low priority)

If you have a friend who speaks any non-English Whisper-supported language nearby:

### Steps
1. Settings → Captions → Language → Output → toggle "Translate to English" on.
2. Have them speak in their language.
3. Captions should appear in English, not the source language.

## What to send back

Just tell me what was wrong / right. I'll batch the fixes into build 17.
