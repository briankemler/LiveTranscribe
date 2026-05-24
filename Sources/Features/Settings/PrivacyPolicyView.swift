import SwiftUI

/// Bundled privacy policy. Pushed from Settings → About → Privacy policy.
/// Authored to reflect Earshot's actual behavior: zero data collection, all processing
/// on-device, one outbound network request on first launch to fetch the Whisper model from
/// Hugging Face, no accounts, no analytics, no third-party SDKs that exfiltrate anything.
struct PrivacyPolicyView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                title: "Privacy policy",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Privacy policy")
                        .font(.scaled(size: 28, weight: .medium, design: .serif, relativeTo: .title1))
                        .tracking(-0.6)
                        .foregroundStyle(theme.ink)

                    Text("Effective 2026-05-16.")
                        .font(.scaled(size: 12, relativeTo: .caption1))
                        .foregroundStyle(theme.inkMute)

                    section("The short version") {
                        Text("Earshot processes audio entirely on your iPhone. We never collect or transmit your speech, your transcripts, or anything else that identifies you. Anything the app remembers — your transcripts, settings, conversation history — stays on this device. No accounts, no analytics, no ads.")
                    }

                    section("What we process and where") {
                        Text("• Microphone audio is captured only while you are on a Live screen. It is fed directly to an on-device transcription model (OpenAI Whisper Small, running locally via the WhisperKit framework) and an on-device sound classifier (Apple SoundAnalysis). Raw audio buffers are processed and discarded — they are never written to disk.")
                        Text("• Transcripts are saved locally on this device using Apple's SwiftData framework. They show up under Settings → Transcripts and in History, and you can delete them at any time by swiping left on a transcript. Transcripts never leave the device unless you explicitly share one via the system share sheet (which sends plain text to the app you choose — Notes, Mail, Messages, etc.).")
                        Text("• Sound detections (e.g., smoke alarm) are stored with the transcript they occurred during, only for display in that conversation's summary.")
                        Text("• Your settings (palette, text size, armed sounds, etc.) are stored locally in iOS UserDefaults. They stay on this device.")
                    }

                    section("Network use") {
                        Text("Earshot makes a single network request on first launch (or when you switch transcription models) to download the Whisper model from Hugging Face (huggingface.co). That download is the only data the app sends or receives over the network. After the model is on your device, the app works fully offline. We do not contact any analytics, advertising, or telemetry servers — there are none.")
                    }

                    section("What we do not do") {
                        Text("• No accounts or sign-in.")
                        Text("• No advertising, no advertising identifiers, no cross-app tracking.")
                        Text("• No analytics SDKs, no crash-reporting SDKs.")
                        Text("• No selling, sharing, or otherwise transferring personal information to third parties — we have none to share.")
                    }

                    section("Permissions") {
                        Text("Microphone access is required for transcription and sound recognition. You can grant, revoke, or check it at any time in iOS Settings → Privacy & Security → Microphone → Earshot.")
                    }

                    section("Children") {
                        Text("Earshot is suitable for general audiences. Because we do not collect personal information from anyone, we do not knowingly collect personal information from children under 13 in the United States, or equivalent ages in other jurisdictions.")
                    }

                    section("Changes") {
                        Text("If we ever change how the app handles data, this screen will be updated and the effective date above will change.")
                    }

                    section("Contact") {
                        Text("Questions, requests, or concerns: brian.kemler@gmail.com")
                    }

                    section("Online version") {
                        Text("This same policy is published at briankemler.github.io/LiveTranscribe/privacy. The in-app and online versions are kept in sync.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .tracking(1.5)
                .foregroundStyle(theme.accent)
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .font(.scaled(size: 14, relativeTo: .subheadline))
            .foregroundStyle(theme.inkSoft)
            .lineSpacing(4)
        }
    }
}
