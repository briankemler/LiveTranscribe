import SwiftUI
import AVFoundation

/// Pushed from Settings → Captions → Speaker labels.
/// Controls how the Live screen labels who's talking.
struct DiarizationSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var bindable = state

        VStack(spacing: 0) {
            TopBar(
                title: "Speaker labels",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Who's talking.")
                        .font(.scaled(size: 28, weight: .medium, design: .serif, relativeTo: .title1))
                        .tracking(-0.6)
                        .foregroundStyle(theme.ink)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        ForEach(Tweaks.Diarization.allCases.indices, id: \.self) { idx in
                            if idx > 0 {
                                Rectangle().fill(theme.line).frame(height: 1)
                            }
                            row(Tweaks.Diarization.allCases[idx], selection: $bindable.tweaks.diarization)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
                    )

                    micReadout
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
    }

    private func row(_ mode: Tweaks.Diarization, selection: Binding<Tweaks.Diarization>) -> some View {
        let isSelected = selection.wrappedValue == mode
        return Button {
            selection.wrappedValue = mode
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.label)
                        .font(.scaled(size: 15, weight: isSelected ? .semibold : .regular, relativeTo: .subheadline))
                        .foregroundStyle(theme.ink)
                    Text(mode.blurb)
                        .font(.scaled(size: 11, relativeTo: .caption2))
                        .foregroundStyle(theme.inkMute)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.scaled(size: 13, weight: .heavy, relativeTo: .footnote))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Read-only readout of the current input device so the user can confirm a multi-channel
    /// interface is recognized. `currentRoute` is safe to read without an active session; channel
    /// counts can read low when no capture is running, so we clamp and explain in copy.
    private var micReadout: some View {
        let inputs = AVAudioSession.sharedInstance().currentRoute.inputs
        let port = inputs.first
        let name = port?.portName ?? "Built-in microphone"
        let channels = max(1, port?.channels?.count ?? 1)
        let isMulti = (port?.portType != .builtInMic) && channels >= 2
        return VStack(alignment: .leading, spacing: 10) {
            Text("MICROPHONES")
                .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                .tracking(1.5)
                .foregroundStyle(theme.inkMute)
            HStack(spacing: 8) {
                Image(systemName: isMulti ? "mic.badge.plus" : "mic.fill")
                    .font(.scaled(size: 14, relativeTo: .subheadline))
                    .foregroundStyle(isMulti ? theme.accent : theme.inkSoft)
                Text("\(name) · \(channels) channel\(channels == 1 ? "" : "s")")
                    .font(.scaled(size: 14, weight: .semibold, relativeTo: .subheadline))
                    .foregroundStyle(theme.ink)
            }
            Text(isMulti
                 ? "Multi-mic mode is available: each channel becomes Mic 1, 2, 3… and each line is tagged with the loudest mic."
                 : "Connect a multi-channel USB-C/Lightning audio interface or mic array to label speakers by microphone. With the built-in mic, group mode uses the pause-based heuristic below.")
                .font(.scaled(size: 12, relativeTo: .caption1))
                .foregroundStyle(theme.inkSoft)
                .lineSpacing(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.surfaceLo)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }

    private var aboutCard: some View {
        Text("In group mode, if a multi-channel audio interface is connected, Earshot labels each line by the microphone that was loudest — real per-mic separation. Otherwise it falls back to a pause-based heuristic: a long enough silence between sentences starts a new \"Speaker N\". That isn't voice fingerprinting — just a good-enough proxy for casual conversation. 1:1 mode doesn't need labels.")
            .font(.scaled(size: 13, relativeTo: .footnote))
            .foregroundStyle(theme.inkSoft)
            .lineSpacing(3)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surfaceLo)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
            )
    }
}
