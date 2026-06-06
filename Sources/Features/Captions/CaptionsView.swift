import SwiftUI
import SwiftData

/// Captions screen — Rev 2.
/// Implements [Design/CAPTIONS_HANDOFF.md](../../../Design/CAPTIONS_HANDOFF.md) and replaces
/// the prior `LiveView`. Backend (LiveSession, transcription, sound recognition, SwiftData)
/// is unchanged — this is purely a view-layer reskin.
///
/// Layout (spec §"Layout"):
///   - Status pill, always visible, top-left.
///   - Sound margin tag (optional, ambient), top-right.
///   - Caption stack centered: previous line dim, current line large with peach caret.
///   - Floating bar at bottom — hidden by default; tap captions area to reveal for 3 s.
///   - Quick-settings bottom sheet from cog.
///   - Silence pill when no speech for ≥ 5 s.
struct CaptionsView: View {
    let mode: LiveMode

    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme
    @Environment(\.tweaks) private var tweaks
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var session: LiveSession?
    @State private var barVisible: Bool = false
    @State private var settingsOpen: Bool = false
    @State private var hideBarTask: Task<Void, Never>?
    /// Build-14: filled when the active conversation `isStarred`. Toggles with star taps.
    @State private var starHighlighted: Bool = false
    @State private var tickerNow: Date = .init()
    /// Drives the "Discard this conversation?" confirmation when the user taps Back with
    /// at least one captured line in flight.
    @State private var discardConfirmShown: Bool = false
    /// Build-14: most recent ambient/social detection; drives the right-margin tag.
    /// Auto-clears after `ambientStaleSeconds` of no fresh detection so the tag doesn't
    /// linger after the room goes quiet.
    @State private var currentAmbientDetection: SoundDetection?
    @State private var ambientClearTask: Task<Void, Never>?

    /// Margin tag fades away if no new ambient hit lands within this window.
    private let ambientStaleSeconds: UInt64 = 8

    /// 1-Hz ticker so the status-pill clock + silence-pill counter update in lockstep.
    /// Re-fires `tickerNow` which drives the recomputed elapsed / silence values.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Derived state

    private var elapsedSeconds: TimeInterval {
        guard let s = session else { return 0 }
        return tickerNow.timeIntervalSince(s.startedAt)
    }

    /// Whole-seconds silence value. Spec §"Silence" turns the pill on at ≥ 5 s.
    private var silenceSeconds: Int {
        Int(session?.silenceSeconds ?? 0)
    }

    private var isSilent: Bool { silenceSeconds >= 5 }

    /// Most recent finalized line for the "previous" caption slot. Spec shows the previous
    /// line above the current. While silent, the *current* line slot stays empty and the
    /// last line is what dims.
    private var previousLine: TranscriptLine? {
        guard let s = session else { return nil }
        return s.lines.last
    }

    /// Current in-progress line. Falls back to a placeholder while the pipeline warms up.
    private var currentLine: TranscriptLine? {
        session?.currentLine
    }

    /// Caption text shown in the "current" slot — real text if we have it, else a status
    /// placeholder describing what the pipeline is doing (loading, downloading, listening).
    private var currentText: String {
        if let line = currentLine { return line.text }
        guard let s = session else { return "Starting up…" }
        // Show the session's own friendly, classified message (permission vs model vs audio).
        // Never the raw error string — that leaked an internal file path on screen.
        if let e = s.error { return e }
        switch s.transcription.loadState {
        case .waitingForWifi:
            return "Waiting for Wi-Fi to download the model."
        case .loading(let p):
            return "Downloading on-device model… \(Int(p * 100))%"
        case .compiling:
            return "Compiling for Neural Engine."
        case .failed:
            return "Couldn't prepare the speech model. Open controls to retry."
        case .idle, .ready:
            return "Listening…"
        }
    }

    /// Recovery control in the error banner — Settings for a permission failure, Retry otherwise.
    @ViewBuilder private var errorActionButton: some View {
        if session?.failureKind == .permission {
            Button("Settings") { openAppSettings() }
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .foregroundStyle(theme.accent)
                .accessibilityLabel("Open Settings")
        } else if session?.error != nil {
            Button("Retry") { Task { await session?.retry() } }
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .foregroundStyle(theme.accent)
                .accessibilityLabel("Retry")
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Body

    var body: some View {
        @Bindable var bindable = state

        ZStack(alignment: .top) {
            // Background tap target — receives reveal taps everywhere except on the bar /
            // sheet. Spec §"Interaction rules" item 1.
            theme.bg
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { revealBar() }

            // Caption region. Group mode uses a fixed, opaque header (status pill + speaker pills)
            // with the chat-bubble feed clipped beneath it — so captions slide *under* the header
            // and can never collide with the pills. 1:1 uses the teleprompter (`.focus` big current
            // line, `.feed` plain scroll) with a floating status pill on top.
            if mode == .group {
                VStack(spacing: 0) {
                    groupHeader
                    bubbleFeed
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                Group {
                    switch tweaks.captionLayout {
                    case .focus:
                        captionStack
                            .padding(.horizontal, 24)
                            .padding(.top, 18)
                            .padding(.bottom, 20)
                    case .feed:
                        captionFeed
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // 1:1 status pill row (floating). Group draws its own inside `groupHeader`.
                HStack(spacing: 8) {
                    backButton
                    CaptionsStatusPill(elapsedSeconds: elapsedSeconds)
                    Spacer()
                    if tweaks.showAmbientSounds && !isSilent, let det = currentAmbientDetection {
                        SoundMarginTag(icon: det.sound.icon, label: det.sound.label)
                            .id(det.sound.classifierID)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentAmbientDetection?.sound.classifierID)
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .animation(.easeInOut(duration: 0.3), value: tweaks.showAmbientSounds)
                .animation(.easeInOut(duration: 0.3), value: isSilent)
            }

            // Silence pill (D1) — centered, only when silent.
            if isSilent {
                CaptionsSilencePill(silenceSeconds: silenceSeconds)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }

            // Tap hint when bar is hidden. Spec §"TAP FOR CONTROLS" line.
            tapHint
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 26)
                .allowsHitTesting(false)

            // Floating control bar — overlay so it sits above everything when visible.
            VStack {
                Spacer()
                CaptionsControlBar(
                    visible: barVisible && !settingsOpen,
                    starHighlighted: starHighlighted,
                    onTapCog: { openSettings() },
                    onTapStar: { tapStar() },
                    onTapPause: { tapPause() }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            // Error banner if the pipeline failed to start, with a recovery action matched to the
            // failure kind: Settings for a permission problem, Retry for a model/audio problem.
            if let err = session?.error {
                VStack {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(err)
                            .font(.scaled(size: 11, relativeTo: .caption2))
                            .foregroundStyle(theme.alert)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        errorActionButton
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.alertSoft)
                    Spacer()
                }
                .padding(.top, 80)
            }

            // Developer transcription-diagnostics overlay (Settings → Developer). The live capture/
            // transcribe telemetry — `rms` is the key one for "is the mic actually capturing?"
            // (0.00 = silence, e.g. a hijacked Bluetooth route); `mic`/input name shows the route.
            if tweaks.showDiagnostics, let s = session {
                VStack {
                    Spacer()
                    Text("rms \(String(format: "%.2f", s.audioLevel)) · chunks \(s.chunksReceived) · buf \(String(format: "%.1f", s.bufferSeconds))s · pass \(s.transcribePasses) · spk \(s.diarizedSpeakerCount) · mic \(s.micCount)\(s.inputName.isEmpty ? "" : " · \(s.inputName)")")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(theme.inkMute)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(theme.surface.opacity(0.85), in: Capsule())
                        .padding(.bottom, 8)
                        .accessibilityHidden(true)
                }
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        // Confirmation when the user taps Back with captured content. No-content case
        // dismisses silently inside `tapBack()` and never reaches this alert.
        .alert("End this conversation?", isPresented: $discardConfirmShown) {
            Button("Save") { confirmSave() }
            // Discard is the highlighted default action — tapping Back is read as "I'm done
            // and I don't want this," so the no-op path is the destructive one.
            Button("Discard", role: .destructive) { confirmDiscard() }
                .keyboardShortcut(.defaultAction)
        } message: {
            Text("Save the transcript or discard it.")
        }
        .sheet(isPresented: $settingsOpen, onDismiss: {
            // Spec §"Interaction rules" item 6: close → resume auto-hide.
            revealBar()
        }) {
            quickSettingsSheet
        }
        // Receive a new tick once per second; cheap recompute of elapsed/silence values.
        // Also re-assert keep-awake every second: setting it once at start can lose the race if
        // `scenePhase` hasn't settled to `.active` yet, and a re-assertion is idempotent/cheap —
        // this guarantees the screen never sleeps while the captions screen is up and foregrounded.
        .onReceive(ticker) { tickerNow = $0; updateKeepAwake() }

        // MARK: Session lifecycle (same wiring as the old LiveView)
        .task {
            let s = LiveSession(
                mode: mode,
                transcription: state.transcription,
                diarization: state.diarization,
                modelContext: modelContext
            )
            s.language = tweaks.transcriptionLanguage.whisperCode
            s.translateToEnglish = tweaks.translateToEnglish
            s.armedSounds = tweaks.armedSounds
            s.soundRecognitionEnabled = tweaks.soundRecognitionEnabled
            s.diarizationEnabled = tweaks.diarization != .off
            s.speakerCountHint = tweaks.groupSpeakerCount.count
            s.tuning = state.diarizationTuning
            session = s
            updateKeepAwake()  // keep the screen awake now that captioning is starting
#if DEBUG
            // App Store screenshot path: `--demo-captions` seeds scripted lines and skips the
            // real mic + model pipeline (the Simulator can't capture audio). Debug-only.
            if ProcessInfo.processInfo.arguments.contains("--demo-captions") {
                s.seedDemoCaptions(
                    history: [
                        .init(speaker: .maya, text: "I had the most ridiculous run this morning —"),
                        .init(speaker: .maya, text: "a goose chased me halfway around the lake."),
                    ],
                    current: .init(speaker: .maya, text: "Honestly though, the espresso here is unreal.")
                )
                return
            }
            // Multi-mic group screen: `--demo-mics N` fakes N mics with rotating activity so the
            // mic pills can be screenshotted/demoed on the Simulator. Debug-only.
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "--demo-mics"), i + 1 < args.count, let n = Int(args[i + 1]) {
                s.seedDemoMics(count: n)
                return
            }
            // Named-speaker group bubbles (Jordan / Maya / Priya / You) for screenshots.
            if args.contains("--demo-group"), let last = SampleScripts.group.last {
                s.seedDemoCaptions(history: Array(SampleScripts.group.dropLast()), current: last)
                return
            }
#endif
            await s.start()
        }
        .onDisappear {
            hideBarTask?.cancel()
            ambientClearTask?.cancel()
            session?.stop()
            // Leaving the captions screen → restore the device's normal Auto-Lock.
            UIApplication.shared.isIdleTimerDisabled = false
        }
        // Keep-awake: re-evaluate whenever the app foregrounds/backgrounds or the session
        // errors out, so the screen only stays lit while we're actually captioning up front.
        .onChange(of: scenePhase) { _, _ in updateKeepAwake() }
        .onChange(of: session?.error) { _, _ in updateKeepAwake() }
        // One handler syncs every live-adjustable tweak onto the running session. Consolidated
        // from six separate `.onChange(of:)` modifiers — the generic chain was tipping the body
        // over the type-checker's complexity limit. Setting all fields each time is cheap and
        // idempotent.
        .onChange(of: tweaks) { _, t in syncSession(with: t) }
        // Developer diarization tuning — apply live to the running session so on-device tweaks
        // take effect on the next pass without restarting the conversation.
        .onChange(of: state.diarizationTuning) { _, t in session?.tuning = t }
        .onChange(of: session?.soundRecognition.lastAmbientDetection) { _, detection in
            // Build-14: route non-urgent classifier hits to the margin tag. We don't push
            // an alert and we don't persist detections (only urgent detections go to the
            // SwiftData record's `SoundDetectionRecord` list).
            guard let detection else { return }
            currentAmbientDetection = detection
            // Re-arm the auto-clear timer so the tag fades if the source goes quiet.
            ambientClearTask?.cancel()
            ambientClearTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: ambientStaleSeconds * 1_000_000_000)
                guard !Task.isCancelled else { return }
                currentAmbientDetection = nil
            }
        }

        // Build-11 VoiceOver behavior preserved: each finalized line posts an announcement.
        .onChange(of: session?.lines.count ?? 0) { _, _ in
            guard UIAccessibility.isVoiceOverRunning, let last = session?.lines.last else { return }
            let phrase = (last.speaker.displayName.isEmpty || last.speaker.displayName == "·")
                ? last.text
                : "\(last.speaker.displayName): \(last.text)"
            UIAccessibility.post(notification: .announcement, argument: phrase)
        }
        .onChange(of: session?.soundRecognition.lastDetection) { _, detection in
            guard let detection else { return }
            session?.recordDetection(detection)
            state.push(.alert(detection))
        }
    }

    // MARK: - Caption stack (spec §"Caption stack")

    /// Previous (dim) + current (peach caret) text columns. Spec values: previous 20 pt
    /// fontDisplay inkDim, current 32 pt × `tweaks.textSize.scale`, ink, letter-spacing -0.8.
    @ViewBuilder
    private var captionStack: some View {
        let prevColor: Color = theme.inkSoft.opacity(isSilent ? 0.22 : 0.40)
        VStack(alignment: .leading, spacing: 0) {
            // Push the caption stack below the status-pill row.
            Spacer().frame(height: mode == .group ? 92 : 56)

            // Previous line — only renders if we have one and we're not currently mid-line
            // OR we're in the silent state (where the "previous" line *is* the last thing
            // said and we dim it further).
            if let prev = previousLine, prev.text.isEmpty == false {
                Text(prev.text)
                    .font(.scaled(size: 20, design: .serif, relativeTo: .title3))
                    .lineSpacing(20 * 0.3)
                    .foregroundStyle(prevColor)
                    .padding(.bottom, 16)
                    .animation(.easeInOut(duration: 0.3), value: isSilent)
                    .accessibilityLabel("Previous: \(prev.text)")
            }

            // Current line — large, peach caret pinned to the end.
            // When silent, suppress the current slot (the spec moves the silence pill into
            // the center instead).
            if !isSilent {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(currentText)
                        .font(.scaled(
                            size: 32 * tweaks.textSize.scale,
                            weight: .medium,
                            design: .serif,
                            relativeTo: .largeTitle
                        ))
                        .tracking(-0.8)
                        .lineSpacing(32 * 0.2)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    BlinkingCaret(height: 26, width: 3)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(currentLineA11yLabel)
                .accessibilityAddTraits(.updatesFrequently)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Caption feed (chat-style scroll — "Star Wars" layout)

    private var feedHistory: [TranscriptLine] {
        session?.lines ?? []
    }

    /// Anchor id for the auto-scroll target — always the in-progress line at the bottom.
    private static let feedBottomID = "caption-feed-bottom"

    /// Chat-style scrolling feed: every finalized line stacked oldest→newest with breathing
    /// room, the in-progress line emphasized at the bottom with the caret, auto-scrolling up
    /// as new lines land. No perspective/shrink — full-size, high-contrast throughout (the
    /// accessibility-friendly take on the requested "Star Wars" scroll).
    private var captionFeed: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Top spacer pushes initial content below the status-pill row.
                    Spacer().frame(height: mode == .group ? 92 : 56)

                    ForEach(feedHistory) { line in
                        feedLine(line.text, emphasized: false)
                            .accessibilityLabel(line.speaker.displayName == "·" || line.speaker.displayName.isEmpty
                                                 ? line.text
                                                 : "\(line.speaker.displayName): \(line.text)")
                    }

                    // In-progress / placeholder line at the bottom — emphasized + caret,
                    // unless we're silent (then the silence pill takes over the screen).
                    if !isSilent {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            feedLine(currentText, emphasized: true)
                            BlinkingCaret(height: 22, width: 3)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(currentLineA11yLabel)
                        .accessibilityAddTraits(.updatesFrequently)
                    }

                    // Invisible scroll anchor.
                    Color.clear
                        .frame(height: 1)
                        .id(Self.feedBottomID)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Tap anywhere in the feed still reveals the control bar, without blocking scroll.
            .simultaneousGesture(TapGesture().onEnded { revealBar() })
            .onChange(of: feedHistory.count) { _, _ in scrollFeedToBottom(proxy) }
            .onChange(of: currentText) { _, _ in scrollFeedToBottom(proxy) }
            .onAppear { scrollFeedToBottom(proxy, animated: false) }
        }
    }

    private func feedLine(_ text: String, emphasized: Bool) -> some View {
        // Emphasized (current) line uses the focus-mode big serif; history uses a calmer,
        // smaller serif at full contrast so older turns stay readable.
        let size: CGFloat = emphasized ? 28 * tweaks.textSize.scale : 19 * tweaks.textSize.scale
        return Text(text)
            .font(.scaled(size: size, weight: emphasized ? .medium : .regular, design: .serif, relativeTo: emphasized ? .title1 : .title3))
            .tracking(-0.5)
            .lineSpacing(size * 0.22)
            .foregroundStyle(emphasized ? theme.ink : theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scrollFeedToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        // Reduce Motion → jump without animation. Otherwise ease to the bottom anchor.
        if animated && !reduceMotion {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(Self.feedBottomID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(Self.feedBottomID, anchor: .bottom)
        }
    }

    /// VoiceOver label for the live caption: speaker + text, falling back to text-only when
    /// the placeholder "·" speaker is showing.
    private var currentLineA11yLabel: String {
        guard let line = currentLine else { return currentText }
        let speaker = line.speaker.displayName
        if speaker.isEmpty || speaker == "·" { return line.text }
        return "\(speaker): \(line.text)"
    }

    // MARK: - Tap hint

    /// "TAP FOR CONTROLS" — fades when the bar is up or the sheet is open. Spec §"Tap hint
    /// when bar hidden".
    private var tapHint: some View {
        Text("TAP FOR CONTROLS")
            .font(.scaled(size: 9, weight: .semibold, relativeTo: .caption2))
            .tracking(1.5)
            .foregroundStyle(theme.inkSoft.opacity(0.22))
            .opacity((barVisible || settingsOpen) ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: barVisible)
            .accessibilityHidden(true)
    }

    /// Keep the screen awake while the captions screen is foreground and the session is
    /// healthy (no mic/permission error), so the display never dims or locks mid-conversation.
    /// `.onDisappear` resets this to `false`, so normal Auto-Lock resumes everywhere else.
    private func updateKeepAwake() {
        UIApplication.shared.isIdleTimerDisabled = (scenePhase == .active && session?.error == nil)
    }

    /// Push every live-adjustable tweak onto the running session. Called from a single
    /// `.onChange(of: tweaks)` so the body stays simple. Idempotent.
    private func syncSession(with t: Tweaks) {
        guard let s = session else { return }
        s.language = t.transcriptionLanguage.whisperCode
        s.translateToEnglish = t.translateToEnglish
        s.armedSounds = t.armedSounds
        s.soundRecognitionEnabled = t.soundRecognitionEnabled
        s.diarizationEnabled = t.diarization != .off
        s.speakerCountHint = t.groupSpeakerCount.count
    }

    /// Quick-settings bottom sheet content. Extracted from `body` so the type-checker doesn't
    /// time out on the already-large body expression.
    private var quickSettingsSheet: some View {
        @Bindable var bindable = state
        return CaptionsQuickSettingsSheet(
            tweaks: $bindable.tweaks,
            openAllSettings: { state.push(.settings) },
            showLayoutRow: mode == .oneToOne,
            showSpeakerCountRow: mode == .group
        )
        // Fitted height detent so the captions stay visible above the sheet. At AX5 the sheet's
        // internal content scrolls rather than spilling.
        .presentationDetents([.height(450)])
        .presentationBackground(theme.surface)
        .presentationDragIndicator(.hidden)  // we draw our own grabber
    }

    // MARK: - Group roster + chat bubbles (cozy layout)

    /// Speakers to show as roster pills. Multi-mic → one per connected mic (Mic 1…N, all shown so
    /// you can see every input). Otherwise → the distinct speakers seen so far, first-appearance order.
    private var rosterSpeakers: [Speaker] {
        if let s = session, s.usesMicDiarization {
            return (1...max(1, s.micCount)).map { Speaker.mic($0) }
        }
        // Fixed speaker count → a deterministic roster of exactly N pills (Speaker 1…N), shown
        // from the start rather than appearing as voices are detected.
        if mode == .group, let n = tweaks.groupSpeakerCount.count {
            return (1...n).map { Speaker.numbered($0) }
        }
        var order: [Speaker] = []
        var seen = Set<String>()
        let all = (session?.lines ?? []) + (currentLine.map { [$0] } ?? [])
        for line in all where seen.insert(line.speaker.id).inserted {
            order.append(line.speaker)
        }
        return order
    }

    /// The speaker currently talking — drives the highlighted roster pill.
    private var activeSpeakerId: String? {
        if let s = session, s.usesMicDiarization, let m = s.activeMic {
            return Speaker.mic(m + 1).id
        }
        return currentLine?.speaker.id
    }

    /// Cozy roster: compact avatar+name pills for each speaker. The active speaker's pill is tinted
    /// with their color; the rest are quiet surface capsules. Uses `FlowLayout` so every pill is
    /// visible — it wraps onto a second row rather than scrolling off-screen (the old horizontal
    /// strip clipped the 4th speaker). With ≤ 4 speakers this is one or two rows.
    private var cozyRoster: some View {
        FlowLayout(spacing: 7, lineSpacing: 7) {
            ForEach(rosterSpeakers) { speaker in
                let color = tweaks.showSpeakerColors ? speaker.color(in: theme) : theme.inkSoft
                let isActive = activeSpeakerId == speaker.id
                HStack(spacing: 6) {
                    Text(speaker.initial)
                        .font(.scaled(size: 9, weight: .heavy, relativeTo: .caption2))
                        .foregroundStyle(.white)
                        .frame(width: 19, height: 19)
                        .background(Circle().fill(color))
                    Text(speaker.displayName)
                        .font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
                        .foregroundStyle(isActive ? theme.ink : theme.inkSoft)
                        .lineLimit(1)
                        .fixedSize()
                }
                .padding(.leading, 4)
                .padding(.trailing, 11)
                .padding(.vertical, 4)
                .background(Capsule().fill(isActive ? color.opacity(0.16) : theme.surface))
                .overlay(Capsule().stroke(isActive ? color : theme.line, lineWidth: 1))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(speaker.displayName)\(isActive ? ", speaking" : "")")
            }
        }
        .animation(.easeInOut(duration: 0.25), value: activeSpeakerId)
        .animation(.easeInOut(duration: 0.25), value: rosterSpeakers)
    }

    /// Chat-style bubble transcript for group mode: one bubble per finalized line plus the live
    /// line at the bottom (emphasized + caret), each with the speaker's avatar. Auto-scrolls.
    private var bubbleFeed: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Spacer().frame(height: 8) // small gap below the opaque header

                    ForEach(feedHistory) { line in
                        bubble(for: line, text: line.text, emphasized: false)
                    }

                    // Live line at the bottom (emphasized). Before the first words land, show a
                    // quiet status line (e.g. "Listening…") instead of an empty bubble.
                    if !isSilent {
                        if let cur = currentLine {
                            bubble(for: cur, text: cur.text, emphasized: true)
                        } else {
                            Text(currentText)
                                .font(.scaled(size: 15, relativeTo: .subheadline))
                                .foregroundStyle(theme.inkMute)
                                .padding(.leading, 46)
                        }
                    }

                    // Inline ambient sound moment (e.g. applause) — mirrors the cozy reference.
                    if tweaks.showAmbientSounds, let det = currentAmbientDetection {
                        ambientChip(det)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Color.clear.frame(height: 1).id(Self.feedBottomID)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .simultaneousGesture(TapGesture().onEnded { revealBar() })
            // Soft-fade only the very top edge of the feed so lines dissolve as they slide under
            // the opaque header (not behind the pills — the header already protects that).
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 14)
                    Color.black
                }
            )
            .onChange(of: feedHistory.count) { _, _ in scrollFeedToBottom(proxy) }
            .onChange(of: currentText) { _, _ in scrollFeedToBottom(proxy) }
            .onAppear { scrollFeedToBottom(proxy, animated: false) }
        }
    }

    /// Opaque group header: status pill row + speaker pills. Drawn above the bubble feed (which is
    /// clipped beneath it), so captions slide under the header and never collide with the pills.
    private var groupHeader: some View {
        VStack(alignment: .leading, spacing: 14) {  // #2: clear gap between status line and pills
            HStack(spacing: 8) {
                backButton
                CaptionsStatusPill(elapsedSeconds: elapsedSeconds)
                Spacer(minLength: 0)
            }
            if !isSilent {
                cozyRoster
                    .padding(.leading, 40)  // #3: align first pill under the status pill (32pt back button + 8pt gap)
            }

            // Diagnostic: an external mic is connected but iOS only gets one channel — i.e. the
            // device is mixing its mics before sending them. Explains why we can't split speakers.
            if let s = session, s.inputIsExternal, s.micCount < 2 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.scaled(size: 10, relativeTo: .caption2))
                    Text("\(s.inputName.isEmpty ? "This mic" : s.inputName) sends one mixed channel — per-mic labels need a multitrack interface")
                        .font(.scaled(size: 10, relativeTo: .caption2))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(theme.inkMute)
                .padding(.leading, 40)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.bg)  // #4: opaque — captions slide underneath, never behind the pills
        .animation(.easeInOut(duration: 0.25), value: isSilent)
    }

    /// One chat bubble: speaker name label, colored avatar circle, and the text card. The live
    /// line renders larger in the display serif with a caret; finalized lines are calmer sans.
    private func bubble(for line: TranscriptLine, text: String, emphasized: Bool) -> some View {
        let color = tweaks.showSpeakerColors ? line.speaker.color(in: theme) : theme.inkSoft
        return VStack(alignment: .leading, spacing: 4) {
            Text(line.speaker.displayName.uppercased())
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .tracking(0.4)
                .foregroundStyle(color)
                .padding(.leading, 46)  // align with the bubble, past the avatar

            HStack(alignment: .center, spacing: 10) {
                Text(line.speaker.initial)
                    .font(.scaled(size: 13, weight: .heavy, relativeTo: .caption1))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(color))

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(text)
                        .font(emphasized
                              ? .scaled(size: 22 * tweaks.textSize.scale, weight: .medium, design: .serif, relativeTo: .title3)
                              : .scaled(size: 16 * tweaks.textSize.scale, relativeTo: .body))
                        .foregroundStyle(emphasized ? theme.ink : theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    if emphasized { BlinkingCaret(height: 18, width: 3) }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(emphasized ? color.opacity(0.5) : theme.line, lineWidth: 1)
                        )
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(line.speaker.displayName): \(text)")
    }

    /// Small centered sound chip shown inline in the bubble feed (ambient/social detections).
    private func ambientChip(_ det: SoundDetection) -> some View {
        HStack(spacing: 6) {
            Image(systemName: det.sound.icon)
                .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
            Text(det.sound.label)
                .font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
        }
        .foregroundStyle(theme.social)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(theme.socialSoft))
        .id(det.sound.classifierID)
    }

    // MARK: - Reveal / hide logic (spec §"Interaction rules" items 1–6)

    /// Show the bar and (re)start the 3-second auto-hide timer. Idempotent — call from
    /// taps + sheet dismissal + any path that should bring the bar back. No-op while the
    /// settings sheet is open (spec item 3).
    private func revealBar() {
        guard !settingsOpen else { return }
        barVisible = true
        scheduleAutoHide()
    }

    private func scheduleAutoHide() {
        hideBarTask?.cancel()
        hideBarTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)  // exactly 3 s per spec
            guard !Task.isCancelled, !settingsOpen else { return }
            barVisible = false
        }
    }

    private func openSettings() {
        hideBarTask?.cancel()
        settingsOpen = true
    }

    /// Star button: bookmark the entire conversation. Build-14 — replaces the per-line star
    /// from build 12. Surfaced via Settings → Transcripts and the History "Starred" filter.
    /// `starHighlighted` reflects the persisted state (filled while saved, hollow when
    /// unstarred) rather than the transient toast it used to be.
    private func tapStar() {
        let nowStarred = session?.starConversation() ?? false
        starHighlighted = nowStarred
        scheduleAutoHide()  // reset 3 s timer per spec — star was a bar-tap-equivalent action
    }

    /// Pause button: spec §"Interaction rules" item 5 — "stop transcription, go to end-of-
    /// conversation save flow." We end the session, persist, and push Summary.
    private func tapPause() {
        guard let id = session?.endAndSave() else {
            // Nothing was persisted; just pop back home.
            state.path = []
            return
        }
        // Replace this screen with the Summary so back-swiping doesn't return to a stopped
        // captions screen.
        state.path = [.summary(id)]
    }

    // MARK: - Back-to-home (deviation from spec — explicit discard path)

    /// Small back chevron paired with the status pill in the top-leading corner.
    /// Always visible (unlike the floating bar) so the escape hatch is one tap away even
    /// when the user hasn't revealed the controls. Discard semantics: tap-with-content →
    /// confirmation alert; tap-empty → silent exit.
    private var backButton: some View {
        Button {
            tapBack()
        } label: {
            Image(systemName: "chevron.left")
                .font(.scaled(size: 13, weight: .heavy, relativeTo: .footnote))
                .foregroundStyle(theme.inkSoft)
                .frame(width: 32, height: 32)
                .background(Circle().fill(theme.surface))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to home")
        .accessibilityHint("Asks whether to save or discard this conversation")
    }

    /// Decide whether to show the confirmation: empty session → exit silently; otherwise
    /// raise the alert. "Empty" = no finalized lines AND no in-progress current line.
    private func tapBack() {
        let hasFinalized = (session?.lines.isEmpty ?? true) == false
        let hasInProgress = session?.currentLine != nil
        if hasFinalized || hasInProgress {
            discardConfirmShown = true
        } else {
            session?.discardAndExit()
            state.path = []
        }
    }

    /// Confirmed discard path — wipe the SwiftData record and pop to Home.
    private func confirmDiscard() {
        session?.discardAndExit()
        state.path = []
    }

    /// Save path from the back-chevron alert — same as tapping Pause: persist and push the
    /// Summary so back-swiping doesn't land on a stopped captions screen.
    private func confirmSave() {
        guard let id = session?.endAndSave() else {
            state.path = []
            return
        }
        state.path = [.summary(id)]
    }
}
