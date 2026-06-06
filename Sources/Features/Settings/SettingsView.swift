import SwiftUI
import SwiftData
import AVFoundation
import UIKit

struct SettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    /// Mic permission, refreshed on each appearance. Permission can only change while the app
    /// is backgrounded, so polling on appearance is enough — no need for a live subscription.
    @State private var micPermission: AVAudioApplication.recordPermission = .undetermined

    /// Live-counts the starred conversations for the Transcripts row label. `@Query` keeps
    /// this in sync without manual refresh — star a conversation on the captions screen,
    /// come back here, count updates.
    @Query(filter: #Predicate<ConversationRecord> { $0.isStarred })
    private var starredConversations: [ConversationRecord]

    /// Hidden developer-tools gate: the Developer section only appears after tapping the Version
    /// row ~7 times (the classic build-number easter egg), so it's invisible to normal users but
    /// always reachable for field debugging. Session-local — re-tap each launch.
    @State private var devTapCount = 0
    @State private var devUnlocked = false
    @State private var devHaptics = UINotificationFeedbackGenerator()

    var body: some View {
        @Bindable var bindable = state
        VStack(spacing: 0) {
            TopBar(
                title: "Settings",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Make it yours.")
                        .font(.scaled(size: 28, weight: .medium, design: .serif, relativeTo: .title1))
                        .tracking(-0.6)
                        .foregroundStyle(theme.ink)
                        .padding(.horizontal, 8)

                    section("Captions", items: [
                        .value(
                            label: "Language",
                            value: state.tweaks.transcriptionLanguage.displayName,
                            action: { state.push(.languageSettings) }
                        ),
                        .value(
                            label: "Transcription model",
                            value: state.tweaks.transcriptionModel.displayName,
                            action: { state.push(.modelSettings) }
                        ),
                        .value(
                            label: "Text size",
                            value: state.tweaks.textSize.label,
                            action: { state.push(.textSizeSettings) }
                        ),
                        .value(
                            label: "Speaker labels",
                            value: state.tweaks.diarization.label,
                            action: { state.push(.diarizationSettings) }
                        ),
                        .toggle(label: "Show speaker colors", binding: $bindable.tweaks.showSpeakerColors),
                    ])

                    section("Sounds", items: [
                        .toggle(
                            label: "Sound recognition",
                            binding: $bindable.tweaks.soundRecognitionEnabled,
                            sub: "Alert me to smoke alarms and other urgent sounds while I'm listening."
                        ),
                        .value(
                            label: "Sound detection",
                            value: state.tweaks.soundRecognitionEnabled ? armedSummary : "Off",
                            action: { state.push(.soundSettings) }
                        ),
                    ])

                    // Build-14: starring a conversation from the captions screen flags it
                    // here. Tap the row to open History; the "Starred" filter is one tap away.
                    section("Transcripts", items: [
                        .value(
                            label: "Saved conversations",
                            value: starredSummary,
                            action: { state.push(.history) }
                        ),
                    ])

                    section("Permissions", items: [
                        .status(
                            label: "Microphone access",
                            value: micStatusLabel,
                            color: micStatusColor,
                            action: { handleMicTap() }
                        ),
                    ])

                    section("About", items: [
                        .tapReadout(label: "Version", value: Self.versionString, action: { registerDevTap() }),
                        .value(
                            label: "Privacy policy",
                            value: "",
                            action: { state.push(.privacyPolicy) }
                        ),
                        .value(
                            label: "Acknowledgements",
                            value: "",
                            action: { state.push(.acknowledgements) }
                        ),
                        .value(
                            label: "Send feedback",
                            value: "",
                            action: { sendFeedback() }
                        ),
                    ])

                    // Hidden until the Version row is tapped ~7 times — keeps dev tools out of the
                    // shipped UI while staying reachable for field debugging.
                    if devUnlocked {
                        section("Developer", items: [
                            .toggle(
                                label: "Show transcription diagnostics",
                                binding: $bindable.tweaks.showDiagnostics,
                                sub: "Overlay RMS · chunks · buffer · pass count · mic on the Live screen"
                            ),
                            .value(
                                label: "Diarization tuning",
                                value: "",
                                action: { state.push(.diarizationTuning) }
                            ),
                            .value(
                                label: "Replay onboarding",
                                value: "",
                                action: { replayOnboarding() }
                            ),
                        ])
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            micPermission = AVAudioApplication.shared.recordPermission
        }
    }

    private enum Item {
        case toggle(label: String, binding: Binding<Bool>, sub: String? = nil)
        case value(label: String, value: String, action: (() -> Void)? = nil)
        case status(label: String, value: String, color: Color, action: (() -> Void)? = nil)
        case readout(label: String, value: String)
        /// A readout (no chevron) that quietly counts taps — used for the hidden dev-tools gate.
        case tapReadout(label: String, value: String, action: () -> Void)
    }

    /// Count taps on the Version row; reveal the Developer section on the 7th.
    private func registerDevTap() {
        guard !devUnlocked else { return }
        devTapCount += 1
        if devTapCount >= 7 {
            withAnimation { devUnlocked = true }
            devHaptics.prepare()
            devHaptics.notificationOccurred(.success)
        }
    }

    /// Build version string, e.g. "0.1.0 (7)". Read from the bundle so it stays in sync with
    /// project.yml's MARKETING_VERSION / CURRENT_PROJECT_VERSION without manual maintenance.
    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    /// Right-side value on the Sound recognition row. "5 of 5 armed" or "Off" when none.
    private var armedSummary: String {
        let total = SoundCatalog.urgent.count
        let armed = state.tweaks.armedSounds.intersection(SoundCatalog.defaultArmedIDs).count
        if armed == 0 { return "Off" }
        return "\(armed) of \(total) armed"
    }

    /// Right-side value on the Transcripts row. "3 starred" / "None starred yet" — `@Query`
    /// keeps `starredConversations` live so this updates without manual refresh.
    private var starredSummary: String {
        let n = starredConversations.count
        if n == 0 { return "None starred yet" }
        return "\(n) starred"
    }

    private var micStatusLabel: String {
        switch micPermission {
        case .granted: "On"
        case .denied: "Denied"
        case .undetermined: "Not yet asked"
        @unknown default: "Unknown"
        }
    }

    private var micStatusColor: Color {
        switch micPermission {
        case .granted: theme.social
        case .denied: theme.alert
        case .undetermined: theme.inkMute
        @unknown default: theme.inkMute
        }
    }

    /// Tap always opens this app's page in iOS Settings — so the user can review or change
    /// mic permission whether it's currently granted, denied, or undetermined. iOS handles
    /// the routing; the deep-link target is the app's own settings pane.
    private func handleMicTap() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    /// Developer affordance: clear the onboarding-seen flag and jump back to step 1 so the
    /// flow can be walked again without reinstalling. Mirrors the `--reset-onboarding` launch
    /// arg used by screenshot tooling.
    private func replayOnboarding() {
        state.onboardingSeen = false
        state.path = [.onboarding1]
    }

    /// Open Mail (or whichever default mail app is set) with a pre-filled feedback message.
    /// The version + device info goes into the body so testers don't have to remember.
    private func sendFeedback() {
        let model = UIDevice.current.model
        let system = UIDevice.current.systemVersion
        let body = """


        ----
        Earshot \(Self.versionString)
        \(model) · iOS \(system)
        """
        let subject = "Earshot \(Self.versionString) feedback"
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "brian.kemler@gmail.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }

    @ViewBuilder
    private func section(_ title: String, items: [Item]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .tracking(1.5)
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 8)

            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { idx in
                    if idx > 0 {
                        Rectangle().fill(theme.line).frame(height: 1)
                    }
                    row(items[idx])
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
            )
        }
    }

    @ViewBuilder
    private func row(_ item: Item) -> some View {
        switch item {
        case .toggle(let label, let binding, let sub):
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.scaled(size: 14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(theme.ink)
                    if let sub {
                        Text(sub).font(.scaled(size: 11, relativeTo: .caption2)).foregroundStyle(theme.inkMute)
                    }
                }
                Spacer(minLength: 0)
                Toggle("", isOn: binding)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: theme.accent))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        case .value(let label, let value, let action):
            Button {
                action?()
            } label: {
                HStack(spacing: 12) {
                    Text(label).font(.scaled(size: 14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(theme.ink)
                    Spacer()
                    if !value.isEmpty {
                        Text(value).font(.scaled(size: 13, relativeTo: .footnote)).foregroundStyle(theme.inkSoft)
                    }
                    Image(systemName: "chevron.right")
                        .font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
                        .foregroundStyle(theme.inkMute)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .status(let label, let value, let color, let action):
            Button {
                action?()
            } label: {
                HStack(spacing: 12) {
                    Text(label).font(.scaled(size: 14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(theme.ink)
                    Spacer()
                    Text(value)
                        .font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
                        .foregroundStyle(color)
                    Image(systemName: "chevron.right")
                        .font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
                        .foregroundStyle(theme.inkMute)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .readout(let label, let value):
            HStack(spacing: 12) {
                Text(label).font(.scaled(size: 14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(theme.ink)
                Spacer()
                Text(value)
                    .font(.scaled(size: 13, relativeTo: .footnote))
                    .monospacedDigit()
                    .foregroundStyle(theme.inkSoft)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        case .tapReadout(let label, let value, let action):
            HStack(spacing: 12) {
                Text(label).font(.scaled(size: 14, weight: .medium, relativeTo: .subheadline)).foregroundStyle(theme.ink)
                Spacer()
                Text(value)
                    .font(.scaled(size: 13, relativeTo: .footnote))
                    .monospacedDigit()
                    .foregroundStyle(theme.inkSoft)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture { action() }
        }
    }
}
