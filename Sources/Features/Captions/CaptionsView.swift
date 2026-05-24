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
        if s.error != nil { return "Microphone unavailable. Open Settings to grant access." }
        switch s.transcription.loadState {
        case .waitingForWifi:
            return "Waiting for Wi-Fi to download the model."
        case .loading(let p):
            return "Downloading on-device model… \(Int(p * 100))%"
        case .compiling:
            return "Compiling for Neural Engine."
        case .failed(let msg):
            return "Couldn't load the model. \(msg)"
        case .idle, .ready:
            return "Listening…"
        }
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

            // Caption region — `.focus` shows the teleprompter stack, `.feed` shows the
            // chat-style scrolling feed. Both sit in the same slot; only the inner content
            // differs. Tapping anywhere still reveals the bar (handled by the bg tap target).
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

            // Status pill row: back chevron (discard + return to home) + always-visible
            // status pill + optional ambient sound tag. Spec §"Status pill"; back button is
            // a deliberate addition to the spec — see plan note in
            // `i-m-resuming-work-on-serene-moon.md` §"Captions: back-to-home affordance".
            HStack(spacing: 8) {
                backButton
                CaptionsStatusPill(elapsedSeconds: elapsedSeconds)
                Spacer()
                // Right-margin sound tag (B2). Build 14: real detections from
                // `SoundRecognitionService.lastAmbientDetection`. Hidden when silent (spec
                // layout), when the master toggle is off, or when no fresh detection is
                // active (auto-clears after `ambientStaleSeconds`).
                if tweaks.showAmbientSounds && !isSilent, let det = currentAmbientDetection {
                    SoundMarginTag(icon: det.sound.icon, label: det.sound.label)
                        .id(det.sound.classifierID)  // forces transition on label change
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentAmbientDetection?.sound.classifierID)
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .animation(.easeInOut(duration: 0.3), value: tweaks.showAmbientSounds)
            .animation(.easeInOut(duration: 0.3), value: isSilent)

            // Group-mode roster strip (deviation from spec — see plan §1). Compact pill row
            // below status pill, suppressed in 1:1 mode and during silence.
            if mode == .group && !isSilent {
                groupRoster
                    .padding(.horizontal, 24)
                    .padding(.top, 52)  // sits just below the status pill
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

            // Error banner if the audio pipeline failed to start (e.g. mic denied).
            if let err = session?.error {
                VStack {
                    Text(err)
                        .font(.scaled(size: 11, relativeTo: .caption2))
                        .foregroundStyle(theme.alert)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.alertSoft)
                    Spacer()
                }
                .padding(.top, 80)
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
            CaptionsQuickSettingsSheet(
                tweaks: $bindable.tweaks,
                openAllSettings: { state.push(.settings) }
            )
            // Build-14: fitted height detent so the captions stay visible above the sheet.
            // `[.medium, .large]` covered ~50% of the screen for 4 rows of content. 380 pt
            // is grabber + title + 4 rows + bottom safe area at default Dynamic Type. At
            // AX5 the sheet's internal content scrolls rather than spilling.
            .presentationDetents([.height(450)])
            .presentationBackground(theme.surface)
            .presentationDragIndicator(.hidden)  // we draw our own grabber
        }
        // Receive a new tick once per second; cheap recompute of elapsed/silence values.
        .onReceive(ticker) { tickerNow = $0 }

        // MARK: Session lifecycle (same wiring as the old LiveView)
        .task {
            let s = LiveSession(mode: mode, transcription: state.transcription, modelContext: modelContext)
            s.language = tweaks.transcriptionLanguage.whisperCode
            s.translateToEnglish = tweaks.translateToEnglish
            s.armedSounds = tweaks.armedSounds
            s.soundRecognitionEnabled = tweaks.soundRecognitionEnabled
            session = s
            await s.start()
        }
        .onDisappear {
            hideBarTask?.cancel()
            ambientClearTask?.cancel()
            session?.stop()
        }
        .onChange(of: tweaks.transcriptionLanguage) { _, v in session?.language = v.whisperCode }
        .onChange(of: tweaks.translateToEnglish)   { _, v in session?.translateToEnglish = v }
        .onChange(of: tweaks.armedSounds)          { _, v in session?.armedSounds = v }
        .onChange(of: tweaks.soundRecognitionEnabled) { _, v in session?.soundRecognitionEnabled = v }
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

    // MARK: - Group roster (deviation from spec)

    /// Compact horizontal speaker pills, 1 per slot in `Speaker.numbered(1...4)`. The
    /// captions spec doesn't show speaker attribution at all, but for group mode we keep a
    /// minimal indicator so users know who's talking. The active speaker uses filled bg.
    private var groupRoster: some View {
        let activeId = currentLine?.speaker.id
        let speakers = (1...4).map { Speaker.numbered($0) }
        return HStack(spacing: 6) {
            ForEach(speakers) { speaker in
                let isActive = activeId == speaker.id
                let color = tweaks.showSpeakerColors ? speaker.color(in: theme) : theme.inkSoft
                Text(speaker.initial)
                    .font(.scaled(size: 9, weight: .heavy, relativeTo: .caption2))
                    .foregroundStyle(isActive ? theme.bg : color)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(isActive ? color : theme.surface))
                    .overlay(Circle().stroke(color, lineWidth: 1))
                    .accessibilityLabel("\(speaker.displayName)\(isActive ? ", speaking" : "")")
            }
            Spacer(minLength: 0)
        }
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
