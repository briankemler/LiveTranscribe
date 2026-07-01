import SwiftUI

struct ModelDownloadingView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var teachIndex: Int = 1
    @State private var shimmerPhase = false
    @State private var teachStartedAt: Date = .now

    private let total: Double = 100
    private let teach: [TeachCard] = TeachCard.all
    /// Size of the model actually being downloaded (the user's choice; new users default to Base).
    private var modelSizeMB: Double { Double(state.tweaks.transcriptionModel.sizeMB) }

    /// The progress bar counts files, not bytes, and this model's bytes live almost entirely in one
    /// or two large weight files — so the bar races through the many tiny files, then crawls while
    /// a big file streams in. Past this point we tell the user it's slow-but-not-stuck.
    private var inBigFileStretch: Bool {
        if case .loading = state.transcription.loadState { return pct >= 55 }
        return false
    }

    /// Real download progress from WhisperKit. 0...1.
    private var pct: Double {
        switch state.transcription.loadState {
        case .idle: return 0
        case .waitingForWifi: return 0
        case .loading(let progress): return progress * 100
        case .compiling: return 100
        case .ready: return 100
        case .failed: return 0
        }
    }

    private var isCompiling: Bool {
        state.transcription.loadState == .compiling
    }

    private var isWaitingForWifi: Bool {
        state.transcription.loadState == .waitingForWifi
    }

    private var kickerText: String {
        if isWaitingForWifi { return "PAUSED · WI-FI REQUIRED" }
        if isCompiling      { return "ALMOST READY" }
        if inBigFileStretch { return "DOWNLOADING · LARGE FILES" }
        return "DOWNLOADING"
    }

    private var mb: Int { Int(pct / 100 * modelSizeMB) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 32)
            Kicker(text: kickerText)
            Spacer().frame(height: 16)

            if isWaitingForWifi {
                AccentItalicTitle(
                    lead: "Waiting for",
                    accentLine: "Wi-Fi.",
                    size: 44,
                    tracking: -1.6
                )
            } else if isCompiling {
                AccentItalicTitle(
                    lead: "Compiling for",
                    accentLine: "Neural Engine.",
                    size: 44,
                    tracking: -1.6
                )
            } else {
                AccentItalicTitle(
                    lead: "Almost yours.",
                    accentLine: "\(Int(pct))% done.",
                    size: 44,
                    tracking: -1.6
                )
                .id(Int(pct))
                .transition(.opacity)
            }

            Spacer().frame(height: 24)
            progressBar
            Spacer().frame(height: 22)

            teachCard

            Spacer(minLength: 16)

            if isWaitingForWifi {
                cellularOverrideCard
            } else {
                lockScreenHint
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await runRealDownload() }
    }

    private var lockScreenHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "cpu")
                .font(.scaled(size: 14, weight: .heavy, relativeTo: .subheadline))
                .foregroundStyle(theme.accent)
            Text(inBigFileStretch
                 ? "Almost there — the final files are the largest, so the bar slows down here. It's still downloading; you can lock the screen and it keeps going in the background."
                 : "You can lock the screen — we'll keep downloading in the background.")
                .font(.scaled(size: 12, relativeTo: .caption1))
                .foregroundStyle(theme.inkSoft)
                .lineSpacing(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.surfaceLo)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
        .padding(.bottom, 28)
    }

    private var cellularOverrideCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
                Text("This \(Int(modelSizeMB)) MB download is paused until Wi-Fi is available.")
                    .font(.scaled(size: 13, relativeTo: .footnote))
                Spacer(minLength: 0)
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
        .padding(.bottom, 16)
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .leading) {
                Capsule().fill(theme.surface)
                GeometryReader { geo in
                    let w = max(0, geo.size.width * pct / total)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [theme.accentDeep, theme.accent],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: w)
                        .shadow(color: theme.accentGlow, radius: 6)

                    // Shimmer — sweeps continuously across the filled bar so it always reads as
                    // "actively downloading", even while a large file crawls the percentage. Masked
                    // to the filled portion. Respects Reduce Motion (no repeating sweep).
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(24, geo.size.width * 0.22))
                        .offset(x: shimmerPhase ? geo.size.width : -geo.size.width * 0.3)
                        .animation(reduceMotion ? nil : .linear(duration: 1.3).repeatForever(autoreverses: false),
                                   value: shimmerPhase)
                        .mask(alignment: .leading) { Capsule().frame(width: w) }
                        .onAppear { shimmerPhase = true }
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(mb) MB of \(Int(modelSizeMB)) MB")
                Spacer()
                Text("Wi-Fi · on-device")
            }
            .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
            .monospacedDigit()
            .foregroundStyle(theme.inkMute)
        }
    }

    private var teachCard: some View {
        let card = teach[teachIndex]
        return VStack(alignment: .leading, spacing: 0) {
            Text("WHILE YOU WAIT · \(teachIndex + 1) OF \(teach.count)")
                .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                .tracking(1.5)
                .foregroundStyle(theme.accent)
                .padding(.bottom, 10)

            (Text(card.lead)
                .font(.scaled(size: 22, weight: .medium, design: .serif, relativeTo: .title2))
                .foregroundStyle(theme.ink)
            + Text(" \(card.italic) ")
                .font(.scaled(size: 22, weight: .medium, design: .serif, relativeTo: .title2).italic())
                .foregroundStyle(theme.accent)
            + Text(card.tail)
                .font(.scaled(size: 22, weight: .medium, design: .serif, relativeTo: .title2))
                .foregroundStyle(theme.ink))
            .lineSpacing(4)
            .tracking(-0.3)
            .fixedSize(horizontal: false, vertical: true)

            FlowLayout(spacing: 6, lineSpacing: 6) {
                SoundChip(systemIcon: "bell.fill", label: "Smoke alarm", tone: .alert)
                SoundChip(systemIcon: "figure.and.child.holdinghands", label: "Baby crying", tone: .alert)
                SoundChip(systemIcon: "bell.and.waves.left.and.right", label: "Doorbell")
                SoundChip(systemIcon: "phone.fill", label: "Phone")
                SoundChip(systemIcon: "speaker.wave.2.fill", label: "Laughter", tone: .social)
            }
            .padding(.top, 14)

            HStack {
                Spacer()
                DotProgress(total: teach.count, current: teachIndex)
                Spacer()
            }
            .padding(.top, 16)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }

    private func runRealDownload() async {

        // Kick off the actual model load (idempotent — does nothing if already loaded).
        let kickoff = Task {
            try? await state.transcription.loadModel()
        }
        defer { kickoff.cancel() }

        // Eagerly fetch the much smaller (~9–22 MB) pyannote diarization models in parallel.
        // We don't gate the "ready" transition on this — it finishes well before Whisper's
        // 244 MB, and group-mode diarization loads it lazily anyway if it isn't done yet.
        let diarizeKickoff = Task {
            try? await state.diarization.loadModel()
        }
        defer { diarizeKickoff.cancel() }

        // While the model loads, rotate the teach cards and watch for completion.
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 1500 : 700))
            // Rotate teach card every ~5 s.
            if Date.now.timeIntervalSince(teachStartedAt) > 5 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    teachIndex = (teachIndex + 1) % teach.count
                    teachStartedAt = .now
                }
            }
            if case .ready = state.transcription.loadState {
                try? await Task.sleep(for: .milliseconds(400))
                state.push(.modelReady)
                return
            }
            if case .failed = state.transcription.loadState {
                // For v1, just stay on this screen with 0% — better failure UX is v2.
                return
            }
        }
    }

    private struct TeachCard {
        let lead: String
        let italic: String
        let tail: String

        static let all: [TeachCard] = [
            TeachCard(lead: "The whole transcription engine runs", italic: "right here", tail: ", on this device."),
            TeachCard(lead: "Sound recognition catches", italic: "96 different sounds", tail: ", from doorbells to smoke alarms."),
            TeachCard(lead: "Your conversations", italic: "never leave", tail: " your phone — not even to us."),
            TeachCard(lead: "Speakers are auto-detected, so", italic: "you don't tag", tail: " who's who."),
        ]
    }
}
