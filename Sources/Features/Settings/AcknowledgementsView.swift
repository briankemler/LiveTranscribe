import SwiftUI

/// Pushed from Settings → About → Acknowledgements. Credits the open-source software bundled
/// or used by the app, with license info for compliance.
struct AcknowledgementsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    private struct Credit: Hashable {
        let name: String
        let attribution: String
        let summary: String
        let licenseName: String
        let url: URL?
    }

    private let credits: [Credit] = [
        Credit(
            name: "WhisperKit",
            attribution: "Argmax, Inc.",
            summary: "On-device speech recognition. Core ML port of OpenAI Whisper. Used for live caption transcription.",
            licenseName: "MIT License",
            url: URL(string: "https://github.com/argmaxinc/WhisperKit")
        ),
        Credit(
            name: "Whisper",
            attribution: "OpenAI",
            summary: "Underlying speech-recognition model weights, run locally via WhisperKit. Models are downloaded on first use and cached on-device.",
            licenseName: "MIT License",
            url: URL(string: "https://github.com/openai/whisper")
        ),
        Credit(
            name: "SoundAnalysis",
            attribution: "Apple Inc.",
            summary: "Built-in iOS framework. Powers on-device urgent-sound detection (smoke alarm, doorbell, baby crying, …). Ships with the OS.",
            licenseName: "Apple System Framework",
            url: URL(string: "https://developer.apple.com/documentation/soundanalysis")
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                title: "Acknowledgements",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Powered by")
                        .font(.scaled(size: 28, weight: .medium, design: .serif, relativeTo: .title1))
                        .tracking(-0.6)
                        .foregroundStyle(theme.ink)

                    ForEach(credits, id: \.self) { creditCard($0) }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func creditCard(_ credit: Credit) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(credit.name)
                    .font(.scaled(size: 16, weight: .semibold, relativeTo: .body))
                    .foregroundStyle(theme.ink)
                Text("· \(credit.attribution)")
                    .font(.scaled(size: 12, relativeTo: .caption1))
                    .foregroundStyle(theme.inkMute)
                Spacer(minLength: 0)
                Text(credit.licenseName)
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(0.5)
                    .foregroundStyle(theme.accent)
            }
            Text(credit.summary)
                .font(.scaled(size: 13, relativeTo: .footnote))
                .foregroundStyle(theme.inkSoft)
                .lineSpacing(3)
            if let url = credit.url {
                Link(url.absoluteString, destination: url)
                    .font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }
}
