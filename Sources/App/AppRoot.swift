import SwiftUI

struct AppRoot: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var state = state

        ZStack {
            theme.bg.ignoresSafeArea()

            NavigationStack(path: $state.path) {
                // Pick the root of the stack based on whether the user has completed onboarding.
                // First launch → onboarding flow; every launch after → home. Honours the
                // `--reset-onboarding` launch arg for testers who want to re-walk the flow.
                routeView(state.onboardingSeen ? .home : .onboarding1)
                    .navigationDestination(for: Route.self) { route in
                        routeView(route)
                    }
            }
            .tint(theme.accent)

            // Floating Tweaks toggle — trailing edge, biased ~30% from top.
            // Top-trailing collides with PrivacyPill / gear / star; bottom-trailing collides with
            // the Live screen's pause button; vertical-center collides with "See all" on Home.
            // 30%-from-top lands in the empty band on every screen.
            // Hidden by default; flipped on via Settings → Developer for dev / demo work so
            // external testers don't see palette / diarization / showcase affordances.
            if state.tweaks.showTweaksPanel {
                GeometryReader { geo in
                    TweaksToggle()
                        .position(x: geo.size.width, y: geo.size.height * 0.30)
                }
                .allowsHitTesting(true)
            }
        }
        .onChange(of: state.tweaks) { _, newValue in
            // Single persistence hook for the entire app — every mutation to `tweaks` flows
            // through `@Observable`, which makes this `onChange` fire.
            TweaksStore.save(newValue)
        }
        .sheet(isPresented: $state.tweaksOpen) {
            TweaksPanel()
                .environment(state)
                .environment(\.theme, theme)
                .environment(\.tweaks, state.tweaks)
                .presentationDetents([.medium, .large])
                .presentationBackground(theme.bgSoft)
        }
        .fullScreenCover(isPresented: $state.showcaseOpen) {
            ShowcaseView()
                .environment(state)
                .environment(\.theme, theme)
                .environment(\.tweaks, state.tweaks)
        }
    }

    @ViewBuilder
    private func routeView(_ route: Route) -> some View {
        switch route {
        case .onboarding1: OnboardingView(step: 0)
        case .onboarding2: OnboardingView(step: 1)
        case .onboarding3: OnboardingView(step: 2)
        case .modelPrep: ModelPrepView()
        case .modelDownloading: ModelDownloadingView()
        case .modelReady: ModelReadyView()
        case .home: HomeView()
        case .history: HistoryView()
        case .live11: CaptionsView(mode: .oneToOne)
        case .liveGroup: CaptionsView(mode: .group)
        case .alert(let detection): AlertView(detection: detection)
        case .typeToSpeak: TypeToSpeakView()
        case .rewind: RewindView()
        case .settings: SettingsView()
        case .soundSettings: SoundSettingsView()
        case .languageSettings: LanguageSettingsView()
        case .modelSettings: ModelSettingsView()
        case .textSizeSettings: TextSizeSettingsView()
        case .diarizationSettings: DiarizationSettingsView()
        case .privacyPolicy: PrivacyPolicyView()
        case .acknowledgements: AcknowledgementsView()
        case .diarizationTuning: DiarizationTuningView()
        case .summary(let id): SummaryView(conversationID: id)
        }
    }
}

/// Side-tab tweaks affordance. Lives on the trailing edge, vertically centered.
/// Half-hidden so it doesn't dominate, but easy to grab.
private struct TweaksToggle: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    var body: some View {
        Button {
            state.tweaksOpen = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
                .foregroundStyle(theme.inkSoft)
                .frame(width: 30, height: 36)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 14,
                        bottomLeadingRadius: 14,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                    .fill(theme.surface.opacity(0.85))
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14,
                            bottomLeadingRadius: 14,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                        .stroke(theme.lineHi, lineWidth: 1)
                    )
                )
                .offset(x: 4) // tuck the right edge into the screen edge
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tweaks")
    }
}
