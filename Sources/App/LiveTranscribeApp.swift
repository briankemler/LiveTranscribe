import SwiftUI
import SwiftData

@main
struct LiveTranscribeApp: App {
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(state)
                .environment(\.theme, state.currentTheme)
                .environment(\.tweaks, state.tweaks)
                .preferredColorScheme(state.currentTheme.isLight ? .light : .dark)
                .tint(state.currentTheme.accent)
                .onOpenURL { url in handle(url) }
                .modelContainer(state.modelContainer)
        }
    }

    /// `livetranscribe://show/<index>` — open showcase mode at a frame index (0-15).
    /// `livetranscribe://route/<name>` — jump the nav stack to a single route.
    /// `livetranscribe://palette/<warm|midnight|paper>` — flip palette.
    private func handle(_ url: URL) {
        guard let host = url.host else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch host {
        case "show":
            let idx = Int(parts.first ?? "0") ?? 0
            state.showcaseIndex = max(0, min(idx, Route.allCases.count - 1))
            state.showcaseOpen = true
        case "route":
            guard let name = parts.first,
                  let route = Route.allCases.first(where: { $0.id == name })
            else { return }
            state.showcaseOpen = false
            state.path = [route]
        case "palette":
            guard let name = parts.first,
                  let palette = PaletteID(rawValue: name)
            else { return }
            state.tweaks.palette = palette
        default: break
        }
    }
}
