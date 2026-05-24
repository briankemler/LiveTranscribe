import SwiftUI
import SwiftData
import Observation

/// Single source of truth for routing + tweaks.
/// MV pattern (per CLAUDE.md): one `@Observable` model drives the whole app; views read directly.
@MainActor
@Observable
final class AppState {
    /// Driver for top-level navigation. Showcase mode jumps directly to a Route to mirror the export deck.
    var path: [Route] = []

    /// Live tweaks panel state. Mutating any field re-renders all subscribed views.
    /// Loaded from `TweaksStore` on init; saved by an `onChange` at `AppRoot`.
    var tweaks: Tweaks

    /// Whether the floating Tweaks sheet is showing.
    var tweaksOpen: Bool = false

    /// Showcase mode (frame-by-frame deck navigation, mirrors the HTML export's slideshow).
    var showcaseOpen: Bool = false
    var showcaseIndex: Int = 0

    /// Wi-Fi vs cellular reachability. Consulted before any model download.
    let network = NetworkMonitor()
    /// Single shared TranscriptionService — model loads once, reused across every Live screen.
    /// Owned here so ModelDownloadingView and LiveView can both observe the same loadState.
    let transcription: TranscriptionService
    /// SwiftData container for conversation history. Views read via `@Query`; `LiveSession`
    /// writes via a `ModelContext` on the shared container.
    let modelContainer: ModelContainer
    /// Persisted "user has finished onboarding" flag. False on first launch, set once we
    /// reach the model-prep / home flow. Lives in `UserDefaults` rather than SwiftData so we
    /// can read it synchronously in `init` to decide the initial nav root.
    var onboardingSeen: Bool {
        didSet { UserDefaults.standard.set(onboardingSeen, forKey: Self.onboardingSeenKey) }
    }
    private static let onboardingSeenKey = "liveTranscribe.onboardingSeen"

    var currentTheme: Theme { tweaks.palette.theme }

    init() {
        self.tweaks = TweaksStore.load()
        self.transcription = TranscriptionService(network: network)
        self.modelContainer = ConversationStore.makeContainer()
        self.onboardingSeen = UserDefaults.standard.bool(forKey: Self.onboardingSeenKey)
        applyLaunchArgs()
    }

    /// Honour `--show <i>`, `--route <name>`, `--palette <warm|midnight|paper>` so screenshot tooling
    /// can deep-link without invoking the iOS "open in app?" prompt.
    private func applyLaunchArgs() {
        let args = CommandLine.arguments
        var i = 1
        while i < args.count {
            switch args[i] {
            case "--show":
                if i + 1 < args.count, let v = Int(args[i + 1]) {
                    showcaseIndex = max(0, min(v, Route.showcaseFrames.count - 1))
                    showcaseOpen = true
                    i += 2; continue
                }
            case "--route":
                if i + 1 < args.count,
                   let route = Route.allCases.first(where: { $0.id == args[i + 1] }) {
                    path = [route]
                    i += 2; continue
                }
            case "--palette":
                if i + 1 < args.count, let p = PaletteID(rawValue: args[i + 1]) {
                    tweaks.palette = p
                    i += 2; continue
                }
            case "--reset-onboarding":
                // Test affordance: forces the onboarding flow to show on the next launch.
                UserDefaults.standard.removeObject(forKey: Self.onboardingSeenKey)
                onboardingSeen = false
                i += 1; continue
            default: break
            }
            i += 1
        }
    }

    // MARK: - Navigation helpers

    func push(_ route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }

    func startLive(_ mode: LiveMode) {
        push(mode == .group ? .liveGroup : .live11)
    }
}
