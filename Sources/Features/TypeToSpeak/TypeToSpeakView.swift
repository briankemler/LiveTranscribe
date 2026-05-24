import SwiftUI

struct TypeToSpeakView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    @State private var text: String = "How about that bookshop in the Mission?"
    @State private var voice: Voice = .warm
    @FocusState private var focused: Bool

    private enum Voice { case warm, clear }

    private let quickReplies = ["Sounds good", "Yes", "No", "Could you repeat that?", "One sec"]

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                title: "Speak as you",
                left: { IconButton(systemName: "xmark", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Close") },
                right: { PrivacyPill() }
            )

            // Last incoming line
            VStack(alignment: .leading, spacing: 4) {
                Text("MAYA")
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(0.4)
                    .foregroundStyle(theme.spkB)
                Text("What do you want to do this weekend?")
                    .font(.scaled(size: 15, relativeTo: .subheadline))
                    .foregroundStyle(theme.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface)
            )
            .overlay(
                Rectangle().fill(theme.spkB).frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)),
                alignment: .leading
            )
            .opacity(0.7)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Compose card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(theme.accent).frame(width: 26, height: 26)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.scaled(size: 13, weight: .heavy, relativeTo: .footnote))
                            .foregroundStyle(theme.onAccent)
                    }
                    Text("I'LL SAY THIS ALOUD")
                        .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                        .tracking(1.2)
                        .foregroundStyle(theme.accent)
                }

                TextEditor(text: $text)
                    .focused($focused)
                    .font(.scaled(size: 26, weight: .medium, design: .serif, relativeTo: .title1))
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .foregroundStyle(theme.ink)
                    .frame(minHeight: 140)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(quickReplies, id: \.self) { reply in
                            Button { text = reply } label: {
                                Text(reply)
                                    .font(.scaled(size: 12, weight: .medium, relativeTo: .caption1))
                                    .foregroundStyle(theme.inkSoft)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(theme.surfaceLo))
                                    .overlay(Capsule().stroke(theme.line, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(theme.surfaceHi)
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(theme.accent, lineWidth: 1.5))
            )
            .shadow(color: theme.accentGlow, radius: 16, y: 8)
            .padding(.horizontal, 16)

            HStack(spacing: 10) {
                Button {
                    voice = (voice == .warm) ? .clear : .warm
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.scaled(size: 13, relativeTo: .footnote))
                            .foregroundStyle(theme.accent)
                        Text("Voice · \(voice == .warm ? "Warm" : "Clear")")
                            .font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
                            .foregroundStyle(theme.ink)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(theme.surface)
                            .overlay(Capsule().stroke(theme.lineHi, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                PrimaryButton(action: { state.path.removeLast() }, label: {
                    Image(systemName: "paperplane.fill").font(.scaled(size: 16, weight: .heavy, relativeTo: .body))
                    Text("Speak now")
                }, fullWidth: false)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
