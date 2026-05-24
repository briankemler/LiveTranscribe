import SwiftUI

struct ModelPrepView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 32)
            Kicker(text: "ONE-TIME SETUP")
            Spacer().frame(height: 18)
            AccentItalicTitle(lead: "Let's bring\nthe model", accentLine: "onto your phone.", size: 50, tracking: -1.8)
            Spacer().frame(height: 18)
            Text("This is what makes everything work without a cloud. You only do this once.")
                .font(.scaled(size: 16, relativeTo: .body))
                .foregroundStyle(theme.inkSoft)
                .lineSpacing(4)
                .frame(maxWidth: 320, alignment: .leading)

            Spacer().frame(height: 28)

            modelCard

            Spacer(minLength: 16)

            footer

            Spacer().frame(height: 16)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await startDownloadIfReady()
        }
        .onChange(of: state.network.reachability) { _, new in
            // User got onto Wi-Fi while we were waiting — auto-resume.
            if new == .wifi, state.transcription.loadState == .waitingForWifi {
                Task { await startDownloadIfReady() }
            }
        }
        .onChange(of: state.transcription.loadState) { _, new in
            // Once the download actually kicks off (progress > 0% or compiling), move to the
            // dedicated download screen so the user gets the rich progress UI. Idempotent —
            // multiple loadState ticks won't push duplicate entries onto the nav stack.
            switch new {
            case .loading, .compiling, .ready:
                if !state.path.contains(.modelDownloading) {
                    state.push(.modelDownloading)
                }
            default: break
            }
        }
    }

    /// The download is automatic over Wi-Fi. If we're on cellular instead, give the user the
    /// explicit choice to spend their cell data rather than waiting.
    @ViewBuilder
    private var footer: some View {
        switch state.transcription.loadState {
        case .waitingForWifi:
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
                    Text("Waiting for Wi-Fi to start the download.")
                        .font(.scaled(size: 13, relativeTo: .footnote))
                }
                .foregroundStyle(theme.inkSoft)

                PrimaryButton(action: {
                    Task { try? await state.transcription.loadModel(allowCellular: true) }
                }) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.scaled(size: 16, weight: .heavy, relativeTo: .body))
                    Text("Download over cellular now")
                }
            }
        default:
            // Wi-Fi available (or already downloading) — auto-trigger via `.task`; show a quiet
            // status so the screen never looks frozen.
            HStack(spacing: 8) {
                Image(systemName: "wifi")
                    .font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
                Text("Starting download over Wi-Fi…")
                    .font(.scaled(size: 13, relativeTo: .footnote))
            }
            .foregroundStyle(theme.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private func startDownloadIfReady() async {
        // No-op if already downloaded / loading; loadModel itself short-circuits.
        try? await state.transcription.loadModel()
    }

    private var modelCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ModelHeroIcon(size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text("OpenAI Whisper · Small")
                        .font(.scaled(size: 15, weight: .bold, relativeTo: .subheadline))
                        .foregroundStyle(theme.ink)
                    Text("Multilingual · 99 languages, auto-detected")
                        .font(.scaled(size: 11, relativeTo: .caption2))
                        .foregroundStyle(theme.inkMute)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)
            .overlay(
                Rectangle().frame(height: 1).foregroundStyle(theme.line),
                alignment: .bottom
            )

            VStack(spacing: 12) {
                row(icon: "icloud.and.arrow.down", title: "244 MB", subtitle: "About 30 seconds on Wi-Fi")
                row(icon: "wind", title: "Wi-Fi by default", subtitle: "Tap below to use cellular if you'd rather not wait")
                row(icon: "lock.fill", title: "Stays on this phone", subtitle: "Never sent back to a server")
            }
            .padding(.top, 14)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.line, lineWidth: 1)
                )
        )
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.accentSoft)
                Image(systemName: icon)
                    .font(.scaled(size: 14, weight: .bold, relativeTo: .subheadline))
                    .foregroundStyle(theme.accent)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote)).foregroundStyle(theme.ink)
                Text(subtitle).font(.scaled(size: 12, relativeTo: .caption1)).foregroundStyle(theme.inkMute)
            }
            Spacer(minLength: 0)
        }
    }
}

/// Phone-with-cube hero icon. Mirrors the inline SVG from `spot-model.jsx`.
struct ModelHeroIcon: View {
    let size: CGFloat
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            // Soft radial halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.accent.opacity(0.35), theme.accent.opacity(0)],
                        center: .init(x: 0.5, y: 0.4),
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )

            // Phone outline
            RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
                .stroke(theme.accent, lineWidth: 2)
                .frame(width: size * 0.4, height: size * 0.65)

            // Cube glyph
            CubeGlyph()
                .stroke(theme.accent, lineWidth: 1.6)
                .background(CubeGlyph().fill(theme.accent.opacity(0.18)))
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(y: size * 0.04)
        }
        .frame(width: size, height: size)
    }
}

private struct CubeGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        let topL = CGPoint(x: 0, y: h * 0.3)
        let topM = CGPoint(x: w / 2, y: 0)
        let topR = CGPoint(x: w, y: h * 0.3)
        let midL = CGPoint(x: 0, y: h * 0.7)
        let midR = CGPoint(x: w, y: h * 0.7)
        let bot  = CGPoint(x: w / 2, y: h)
        let cnt  = CGPoint(x: w / 2, y: h * 0.45)
        p.move(to: topL)
        p.addLine(to: topM)
        p.addLine(to: topR)
        p.addLine(to: midR)
        p.addLine(to: bot)
        p.addLine(to: midL)
        p.closeSubpath()
        // inner faces
        p.move(to: topL)
        p.addLine(to: cnt)
        p.addLine(to: topR)
        p.move(to: cnt)
        p.addLine(to: bot)
        return p
    }
}
