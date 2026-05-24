import SwiftUI

/// Dedicated sub-screen for picking the Whisper model size. Pushed from Settings → Captions →
/// Transcription model. Switching is async: the picked model loads in the background, and the
/// row shows download progress until it's `Ready`.
struct ModelSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    @State private var pendingDeletion: WhisperModelChoice?

    private var lightModels: [WhisperModelChoice] {
        WhisperModelChoice.allCases.filter { $0.tier == .light }
    }
    private var balancedModels: [WhisperModelChoice] {
        WhisperModelChoice.allCases.filter { $0.tier == .balanced }
    }

    private func isDownloaded(_ choice: WhisperModelChoice) -> Bool {
        state.transcription.downloadedModels.contains(choice.whisperKitName)
    }

    var body: some View {
        @Bindable var bindable = state

        VStack(spacing: 0) {
            TopBar(
                title: "Transcription model",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Speed versus accuracy.")
                        .font(.scaled(size: 28, weight: .medium, design: .serif, relativeTo: .title1))
                        .tracking(-0.6)
                        .foregroundStyle(theme.ink)
                        .padding(.horizontal, 8)

                    section(title: "LIGHTEST", color: theme.inkMute, models: lightModels)
                    section(title: "BALANCED", color: theme.accent,  models: balancedModels)

                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            pendingDeletion.map { "Delete \($0.displayName)?" } ?? "",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { choice in
            Button("Delete \(choice.sizeLabel)", role: .destructive) {
                Task {
                    try? await state.transcription.removeModel(choice.whisperKitName)
                    pendingDeletion = nil
                }
            }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { choice in
            Text("Frees \(choice.sizeLabel) on this phone. You can re-download anytime.")
        }
    }

    // MARK: - Tier section

    @ViewBuilder
    private func section(title: String, color: Color, models: [WhisperModelChoice]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title)
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(1.5)
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 8)

            VStack(spacing: 0) {
                ForEach(models.indices, id: \.self) { idx in
                    if idx > 0 {
                        Rectangle().fill(theme.line).frame(height: 1)
                    }
                    modelRow(models[idx])
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
            )
        }
    }

    // MARK: - Row

    private func modelRow(_ choice: WhisperModelChoice) -> some View {
        let isSelected = state.tweaks.transcriptionModel == choice
        let isLoadedNow = state.transcription.loadedModelName == choice.whisperKitName
        let isOnDisk = isDownloaded(choice)
        // Trash button shows for cached, non-active models — we never let the user delete the model
        // currently in use.
        let canDelete = isOnDisk && !isSelected && !isLoadedNow

        return HStack(alignment: .top, spacing: 12) {
            Button {
                pickModel(choice)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(choice.displayName)
                            .font(.scaled(size: 15, weight: isSelected ? .semibold : .regular, relativeTo: .subheadline))
                            .foregroundStyle(theme.ink)
                        // Tiny green dot for cached-but-not-selected models — confirms "you've
                        // downloaded this one already, tap to switch instantly".
                        if isOnDisk && !isSelected {
                            Circle()
                                .fill(theme.social)
                                .frame(width: 6, height: 6)
                                .accessibilityLabel("Downloaded")
                        }
                        Spacer()
                        Text(choice.sizeLabel)
                            .font(.scaled(size: 12, relativeTo: .caption1))
                            .monospacedDigit()
                            .foregroundStyle(theme.inkMute)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.scaled(size: 13, weight: .heavy, relativeTo: .footnote))
                                .foregroundStyle(theme.accent)
                        }
                    }
                    Text(choice.blurb)
                        .font(.scaled(size: 12, relativeTo: .caption1))
                        .foregroundStyle(theme.inkMute)
                        .lineSpacing(2)
                    rowStatusText(for: choice, isSelected: isSelected, isLoadedNow: isLoadedNow, isOnDisk: isOnDisk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if canDelete {
                Button {
                    pendingDeletion = choice
                } label: {
                    Image(systemName: "trash")
                        .font(.scaled(size: 14, weight: .semibold, relativeTo: .subheadline))
                        .foregroundStyle(theme.inkMute)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(theme.surfaceLo)
                                .overlay(Circle().stroke(theme.line, lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(choice.displayName)")
                // Nudge it up so it aligns with the title row visually.
                .offset(y: -4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func rowStatusText(
        for choice: WhisperModelChoice,
        isSelected: Bool,
        isLoadedNow: Bool,
        isOnDisk: Bool
    ) -> some View {
        if isSelected {
            if case .loading(let p) = state.transcription.loadState {
                Text("Downloading · \(Int(p * 100))%")
                    .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                    .foregroundStyle(theme.accent)
                    .monospacedDigit()
            } else if state.transcription.loadState == .waitingForWifi {
                Button {
                    Task { try? await state.transcription.loadModel(allowCellular: true) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wifi.exclamationmark").font(.scaled(size: 10, weight: .bold, relativeTo: .caption2))
                        Text("Waiting for Wi-Fi · Tap to use cellular")
                            .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                    }
                    .foregroundStyle(theme.accent)
                }
                .buttonStyle(.plain)
            } else if state.transcription.loadState == .compiling {
                Text("Compiling for Neural Engine…")
                    .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                    .foregroundStyle(theme.accent)
            } else if isLoadedNow {
                Text("Active · ready on this phone")
                    .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                    .foregroundStyle(theme.social)
            } else if isOnDisk {
                Text("Selected · loads on first use")
                    .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                    .foregroundStyle(theme.accent)
            } else {
                Text("Selected · will download \(choice.sizeLabel) on first use")
                    .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                    .foregroundStyle(theme.accent)
            }
        } else if isOnDisk {
            Text("Downloaded · tap to switch instantly")
                .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                .foregroundStyle(theme.social)
        } else {
            Text("Will download \(choice.sizeLabel)")
                .font(.scaled(size: 11, relativeTo: .caption2))
                .foregroundStyle(theme.inkMute)
        }
    }

    private func pickModel(_ choice: WhisperModelChoice) {
        state.tweaks.transcriptionModel = choice
        Task {
            try? await state.transcription.setModel(choice.whisperKitName)
        }
    }

    // MARK: - About

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            (Text("Models you've downloaded show a ")
                .foregroundStyle(theme.inkSoft)
            + Text("green dot")
                .foregroundStyle(theme.social).fontWeight(.semibold)
            + Text(" — tap one to switch instantly, no re-download. Tap the trash to free its space; you can pull it back down anytime. Downloads only run on Wi-Fi unless you tap to use cellular.")
                .foregroundStyle(theme.inkSoft))
                .font(.scaled(size: 13, relativeTo: .footnote))
                .lineSpacing(3)

            Text("Whisper Small is the recommended default — it's the best balance of accuracy and real-time performance on iPhone. Tiny and Base are faster but miss more words; useful if you're on an older phone or want to save space.")
                .font(.scaled(size: 12, relativeTo: .caption1))
                .foregroundStyle(theme.inkMute)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.surfaceLo)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }
}
