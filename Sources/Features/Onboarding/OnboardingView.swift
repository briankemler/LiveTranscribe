import SwiftUI
import AVFoundation

struct OnboardingView: View {
    let step: Int

    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    /// Tracks whether step 2's "Continue" button is currently waiting on the iOS permission
    /// prompt. While true we disable the button so the user can't double-tap.
    ///
    /// Per App Review Guideline 5.1.1(iv): the pre-permission priming screen's button must use
    /// neutral wording ("Continue"/"Next"), not "Allow", since the actual grant decision belongs
    /// to the system prompt. The button still triggers `requestRecordPermission()` on tap.
    @State private var isRequestingMic = false

    private var content: StepContent { StepContent.all[step] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 32)
                Kicker(text: content.kicker)
                Spacer().frame(height: 18)
                AccentItalicTitle(lead: content.lead, accentLine: content.accent)
                    .id(step)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                Spacer().frame(height: 20)
                Text(content.body)
                    .font(.scaled(size: 17, relativeTo: .body))
                    .foregroundStyle(theme.inkSoft)
                    .lineSpacing(4)
                    .frame(maxWidth: 320, alignment: .leading)

                Spacer(minLength: 24)

                visual
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 24)

                DotProgress(total: 3, current: step)
                    .frame(maxWidth: .infinity)

                Spacer().frame(height: 16)

                PrimaryButton(action: advance) {
                    Text(content.cta)
                }

                if step < 2 {
                    Button {
                        finish()
                    } label: {
                        Text("Skip")
                            .font(.scaled(size: 13, relativeTo: .footnote))
                            .foregroundStyle(theme.inkMute)
                            .frame(height: 36)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, 28)
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func advance() {
        switch step {
        case 0: state.push(.onboarding2)
        case 1: requestMicAndAdvance()
        default: finish()
        }
    }

    /// Step 2's CTA actually triggers the iOS mic prompt now. We advance regardless of
    /// outcome — a denied user will see the Permissions row in Settings later and can fix it
    /// there. The audio session won't be created until they hit a Live screen.
    private func requestMicAndAdvance() {
        guard !isRequestingMic else { return }
        let current = AVAudioApplication.shared.recordPermission
        if current == .granted || current == .denied {
            // Already decided — no system prompt would appear. Just advance.
            state.push(.onboarding3)
            return
        }
        isRequestingMic = true
        Task {
            _ = await AVAudioApplication.requestRecordPermission()
            await MainActor.run {
                isRequestingMic = false
                state.push(.onboarding3)
            }
        }
    }

    private func finish() {
        // Mark onboarding as seen — next launch will skip to Home directly.
        state.onboardingSeen = true
        state.path = [.modelPrep]
    }

    @ViewBuilder
    private var visual: some View {
        switch content.visualKind {
        case .hero: OnbHeroVisual()
        case .privacy: OnbPrivacyVisual()
        case .preview: OnbPreviewVisual()
        }
    }
}

// MARK: - Step content

private struct StepContent {
    let kicker: String
    let lead: String
    let accent: String
    let body: String
    let cta: String
    let visualKind: VisualKind
    enum VisualKind { case hero, privacy, preview }

    static let all: [StepContent] = [
        StepContent(
            kicker: "EARSHOT",
            lead: "Every voice.",
            accent: "Every sound.",
            body: "Fast, free and private captions.",
            cta: "Continue",
            visualKind: .hero
        ),
        StepContent(
            kicker: "PRIVACY",
            lead: "What happens here,",
            accent: "stays here.",
            body: "Earshot uses the microphone to caption the conversation around you. The Whisper model runs on your phone, so audio stays here and never leaves your device.",
            cta: "Continue",
            visualKind: .privacy
        ),
        StepContent(
            kicker: "HOW IT WORKS",
            lead: "Hold up.",
            accent: "Read along.",
            body: "Set the phone between you and a speaker. Tap start. Captions appear instantly.",
            cta: "I'm ready",
            visualKind: .preview
        ),
    ]
}

// MARK: - Visuals

private struct OnbHeroVisual: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floating = false

    var body: some View {
        VStack(spacing: 24) {
            // V6 brand mark
            BubbleMark(size: 200)
                .offset(y: floating ? -4 : 4)
                .animation(
                    reduceMotion
                        ? .default
                        : .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                    value: floating
                )
                .onAppear { floating = true }

            // Small below-the-bubble caption to hint at what the app does
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.scaled(size: 11, relativeTo: .caption2))
                    Text("laughter · jazz · espresso hiss")
                        .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                }
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(theme.accentSoft))
            }
        }
    }
}

private struct OnbPrivacyVisual: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(theme.accentSoft, lineWidth: 1)
                    .frame(width: 164, height: 164)
                    .opacity(0.5)
                Circle()
                    .stroke(theme.accentSoft, lineWidth: 1)
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(theme.surface)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle().stroke(theme.lineHi, lineWidth: 1)
                    )
                Image(systemName: "lock.fill")
                    .font(.scaled(size: 44, weight: .medium, relativeTo: .largeTitle))
                    .foregroundStyle(theme.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                row(icon: "cpu", text: "Audio processed on-device")
                row(icon: "wind", text: "Works offline, no account")
                row(icon: "star.fill", text: "You choose what to save")
            }
        }
    }

    private func row(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.scaled(size: 14, relativeTo: .subheadline))
                .foregroundStyle(theme.accent)
                .frame(width: 16)
            Text(text)
                .font(.scaled(size: 13, relativeTo: .footnote))
                .foregroundStyle(theme.inkSoft)
        }
    }
}

private struct OnbPreviewVisual: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.accentSoft.opacity(0.4))
                    .frame(width: 96, height: 96)
                    .scaleEffect(pulsing ? 1.18 : 1)
                    .opacity(pulsing ? 0 : 0.7)
                    .animation(
                        reduceMotion
                            ? .default
                            : .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: pulsing
                    )
                Circle()
                    .fill(theme.accentSoft)
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(theme.accent)
                    .frame(width: 64, height: 64)
                Image(systemName: "mic.fill")
                    .font(.scaled(size: 28, weight: .semibold, relativeTo: .title1))
                    .foregroundStyle(theme.onAccent)
            }
            .onAppear { pulsing = true }

            Text("tap and start talking")
                .font(.scaled(size: 12, weight: .medium, relativeTo: .caption1))
                .foregroundStyle(theme.inkMute)
        }
    }
}
