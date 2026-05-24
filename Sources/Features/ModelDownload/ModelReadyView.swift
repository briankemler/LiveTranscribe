import SwiftUI

struct ModelReadyView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var checkedIn = false

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            // Soft accent radial
            RadialGradient(
                colors: [theme.accentSoft, .clear],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 56)
                checkmark
                    .frame(maxWidth: .infinity)

                Spacer().frame(height: 28)
                Kicker(text: "READY")
                    .frame(maxWidth: .infinity)

                Spacer().frame(height: 12)
                AccentItalicTitle(lead: "It's all", accentLine: "here now.", size: 48, tracking: -1.6)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 14)
                Text("Earshot is fully on your phone. No connection needed from here on.")
                    .font(.scaled(size: 15, relativeTo: .subheadline))
                    .foregroundStyle(theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 280)
                    .frame(maxWidth: .infinity)

                Spacer().frame(height: 28)
                statRow

                Spacer(minLength: 16)

                PrimaryButton(action: { state.path = [.home] }) {
                    Image(systemName: "mic.fill").font(.scaled(size: 16, weight: .heavy, relativeTo: .body))
                    Text("Try it out")
                }
                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 28)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if reduceMotion { checkedIn = true }
            else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { checkedIn = true }
            }
        }
    }

    private var checkmark: some View {
        ZStack {
            Circle()
                .fill(theme.accentSoft)
                .frame(width: 116, height: 116)
            Circle()
                .fill(theme.accent)
                .frame(width: 96, height: 96)
                .shadow(color: theme.accentGlow, radius: 24, y: 12)
            Image(systemName: "checkmark")
                .font(.scaled(size: 48, weight: .heavy, relativeTo: .largeTitle))
                .foregroundStyle(theme.onAccent)
                .scaleEffect(checkedIn ? 1 : 0.4)
                .opacity(checkedIn ? 1 : 0)
        }
    }

    private var statRow: some View {
        // Pull real numbers from the actual model/catalog rather than hardcoding aspirational
        // values. Disk = selected Whisper variant; alerts = urgent sound catalog size.
        let model = state.tweaks.transcriptionModel
        return HStack(spacing: 8) {
            stat(n: "\(model.sizeMB)", label: "MB on disk")
            stat(n: "\(SoundCatalog.urgent.count)", label: model.id == "tiny" ? "urgent alerts" : "urgent alerts")
            stat(n: "0", label: "to the cloud")
        }
    }

    private func stat(n: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(n)
                .font(.scaled(size: 24, weight: .semibold, design: .serif, relativeTo: .title2))
                .foregroundStyle(theme.ink)
            Text(label.uppercased())
                .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(theme.inkMute)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }
}
