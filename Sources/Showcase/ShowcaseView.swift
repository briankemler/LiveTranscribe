import SwiftUI

/// Mirrors the export deck: walk all 16 frames in order with prev/next + counter.
/// This is the iOS equivalent of `Live Transcribe - Spotlight (export).html`.
struct ShowcaseView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var routes: [Route] { Route.showcaseFrames }

    var body: some View {
        @Bindable var state = state

        let route = routes[min(state.showcaseIndex, routes.count - 1)]

        // Slide content gets full real estate; chrome lives in safeAreaInsets so it doesn't overlap.
        screenView(for: route)
            .id(route)
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(route.section.uppercased())
                            .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                            .tracking(2)
                            .foregroundStyle(theme.accent)
                        Text(route.label)
                            .font(.scaled(size: 13, weight: .semibold, design: .serif, relativeTo: .footnote))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                            .foregroundStyle(theme.inkSoft)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(theme.surfaceLo).overlay(Circle().stroke(theme.lineHi, lineWidth: 1)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close showcase")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.bgSoft.opacity(0.95))
                .overlay(Rectangle().frame(height: 1).foregroundStyle(theme.line), alignment: .bottom)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack(spacing: 8) {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            state.showcaseIndex = max(0, state.showcaseIndex - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.scaled(size: 14, weight: .heavy, relativeTo: .subheadline))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    .disabled(state.showcaseIndex == 0)
                    .opacity(state.showcaseIndex == 0 ? 0.4 : 1)
                    .accessibilityLabel("Previous frame")

                    Text("\(state.showcaseIndex + 1) / \(routes.count)")
                        .font(.scaled(size: 12, weight: .medium, relativeTo: .caption1))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 12)

                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            state.showcaseIndex = min(routes.count - 1, state.showcaseIndex + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.scaled(size: 14, weight: .heavy, relativeTo: .subheadline))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    .disabled(state.showcaseIndex == routes.count - 1)
                    .opacity(state.showcaseIndex == routes.count - 1 ? 0.4 : 1)
                    .accessibilityLabel("Next frame")
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Showcase navigation, frame \(state.showcaseIndex + 1) of \(routes.count)")
                .padding(8)
                .background(Capsule().fill(.black.opacity(0.6)))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
            .background(theme.bg.ignoresSafeArea())
    }

    @ViewBuilder
    private func screenView(for route: Route) -> some View {
        // Each frame stands alone — wrap in a fresh navigation-free container so back-stack mutations don't blow up.
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
        case .summary(let id): SummaryView(conversationID: id)
        }
    }
}
