import SwiftUI

/// Dedicated sub-screen for picking the transcription language. Pushed from Settings → Captions →
/// Language. Holds both the picker and the explanatory tier breakdown so neither clutters the main
/// Settings list. Mirrors Apple's pattern in Settings → General → Language & Region.
struct LanguageSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    private var excellentLanguages: [TranscriptionLanguage] {
        TranscriptionLanguage.allCases.filter { $0.tier == .excellent }
    }

    private var strongLanguages: [TranscriptionLanguage] {
        TranscriptionLanguage.allCases.filter { $0.tier == .strong }
    }

    var body: some View {
        @Bindable var bindable = state

        VStack(spacing: 0) {
            TopBar(
                title: "Language",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("What we expect speakers\nto be using.")
                        .font(.scaled(size: 28, weight: .medium, design: .serif, relativeTo: .title1))
                        .tracking(-0.6)
                        .lineSpacing(2)
                        .foregroundStyle(theme.ink)
                        .padding(.horizontal, 8)

                    autoSection(selection: $bindable.tweaks.transcriptionLanguage)

                    section(
                        title: "EXCELLENT",
                        headerColor: theme.accent,
                        languages: excellentLanguages,
                        selection: $bindable.tweaks.transcriptionLanguage
                    )

                    section(
                        title: "STRONG",
                        headerColor: theme.social,
                        languages: strongLanguages,
                        selection: $bindable.tweaks.transcriptionLanguage
                    )

                    outputSection(translate: $bindable.tweaks.translateToEnglish)

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

    // MARK: - Auto-detect (its own card)

    private func autoSection(selection: Binding<TranscriptionLanguage>) -> some View {
        let isSelected = selection.wrappedValue == .auto
        return Button {
            selection.wrappedValue = .auto
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-detect")
                        .font(.scaled(size: 16, weight: .semibold, relativeTo: .body))
                        .foregroundStyle(theme.ink)
                    Text("Picks the language each window. Best when speakers switch languages or you're not sure.")
                        .font(.scaled(size: 12, relativeTo: .caption1))
                        .foregroundStyle(theme.inkMute)
                        .lineSpacing(2)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.scaled(size: 14, weight: .heavy, relativeTo: .subheadline))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? theme.accent : theme.line, lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tiered language list

    private func section(
        title: String,
        headerColor: Color,
        languages: [TranscriptionLanguage],
        selection: Binding<TranscriptionLanguage>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(headerColor).frame(width: 8, height: 8)
                Text(title)
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(1.5)
                    .foregroundStyle(headerColor)
            }
            .padding(.horizontal, 8)

            VStack(spacing: 0) {
                ForEach(languages.indices, id: \.self) { idx in
                    if idx > 0 {
                        Rectangle().fill(theme.line).frame(height: 1)
                    }
                    languageRow(languages[idx], selection: selection)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
            )
        }
    }

    private func languageRow(_ lang: TranscriptionLanguage, selection: Binding<TranscriptionLanguage>) -> some View {
        let isSelected = selection.wrappedValue == lang
        return Button {
            selection.wrappedValue = lang
        } label: {
            HStack {
                Text(lang.displayName)
                    .font(.scaled(size: 14, weight: isSelected ? .semibold : .regular, relativeTo: .subheadline))
                    .foregroundStyle(theme.ink)
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

    // MARK: - Output

    /// Toggle row controlling whether Whisper transcribes in the spoken language (off) or
    /// translates everything to English (on). Whisper's `.translate` task is one-directional
    /// (any → English), so this is a true binary toggle, not a target-language picker.
    private func outputSection(translate: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(theme.accent).frame(width: 8, height: 8)
                Text("OUTPUT")
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(1.5)
                    .foregroundStyle(theme.accent)
            }
            .padding(.horizontal, 8)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Translate to English")
                        .font(.scaled(size: 14, weight: .medium, relativeTo: .subheadline))
                        .foregroundStyle(theme.ink)
                    Text("Non-English speech is translated to English on the fly. Off = captions stay in the spoken language.")
                        .font(.scaled(size: 11, relativeTo: .caption2))
                        .foregroundStyle(theme.inkMute)
                        .lineSpacing(2)
                }
                Spacer(minLength: 0)
                Toggle("", isOn: translate)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: theme.accent))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.line, lineWidth: 1))
            )
        }
    }

    // MARK: - About card

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            (Text("Earshot runs Whisper Small on this phone. The model already covers ")
                .foregroundStyle(theme.inkSoft)
            + Text("99 languages")
                .foregroundStyle(theme.ink).fontWeight(.semibold)
            + Text(" — switching languages above doesn't download anything, it just tells the model what to listen for.")
                .foregroundStyle(theme.inkSoft))
                .font(.scaled(size: 13, relativeTo: .footnote))
                .lineSpacing(3)

            Text("Flip the Translate toggle above to translate any of those 99 languages to English instead of transcribing in source. Translation is one-directional — Whisper translates any source to English, but not the other way.")
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
