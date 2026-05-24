import SwiftUI

/// Pushed from Settings → Sounds → Sound detection. Build-16 split:
///
/// - **Urgent** (top section) → user picks which sounds raise `AlertView`. Soft cap at
///   `SoundCatalog.maxUrgent` (6). Unarmed chips dim when the cap is reached.
/// - **What we listen for** (everything below) → categorized read-only display of the
///   non-urgent catalog. The recognizer auto-arms every ID here whenever
///   `tweaks.showAmbientSounds` is on; there's no per-chip selection to make. Detections
///   surface as the right-margin tag on the captions screen.
///
/// Master switches: `tweaks.soundRecognitionEnabled` (urgent path) and
/// `tweaks.showAmbientSounds` (margin tag visibility).
struct SoundSettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    private var armedCount: Int {
        SoundCatalog.urgent.filter { SoundCatalog.isArmed($0, in: state.tweaks.armedSounds) }.count
    }

    private var atCap: Bool { armedCount >= SoundCatalog.maxUrgent }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                title: "Sound recognition",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            VStack(alignment: .leading, spacing: 8) {
                AccentItalicTitle(lead: "What should we", accentLine: "alert you to?", size: 28, lineHeight: 1.15, tracking: -0.6)
                Text("Pick up to \(SoundCatalog.maxUrgent) sounds for full-screen alerts. Everything else is auto-tagged on the captions screen.")
                    .font(.scaled(size: 13, relativeTo: .footnote))
                    .foregroundStyle(theme.inkSoft)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    urgentSection
                    listeningHeader
                    ForEach(SoundCatalog.nonUrgentSections) { section in
                        nonUrgentSection(section)
                    }
                    aboutCard.padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Urgent

    private var urgentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader("URGENT · ALERT ME LOUD", color: theme.alert)
                Spacer(minLength: 0)
                Text("\(armedCount) / \(SoundCatalog.maxUrgent)")
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(0.5)
                    .foregroundStyle(atCap ? theme.alert : theme.inkMute)
                    .monospacedDigit()
            }
            flow(SoundCatalog.urgent) { sound in urgentChip(sound) }
        }
    }

    private func urgentChip(_ sound: UrgentSound) -> some View {
        let isArmed = SoundCatalog.isArmed(sound, in: state.tweaks.armedSounds)
        let isDisabled = !isArmed && atCap   // grey out unarmed chips once the cap is hit
        return Button {
            toggleUrgent(sound)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: sound.icon).font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
                Text(sound.label).font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
                Image(systemName: isArmed ? "checkmark" : "plus")
                    .font(.scaled(size: 12, weight: .heavy, relativeTo: .caption1))
            }
            .foregroundStyle(chipForeground(isArmed: isArmed, isDisabled: isDisabled))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Capsule().fill(chipBackground(isArmed: isArmed, isDisabled: isDisabled))
            )
            .overlay(
                Capsule().stroke(chipStroke(isArmed: isArmed, isDisabled: isDisabled), lineWidth: isArmed ? 0 : 1)
            )
            .opacity(isDisabled ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel("\(sound.label), \(isArmed ? "armed" : isDisabled ? "unavailable, alert cap reached" : "off")")
        .accessibilityAddTraits(isArmed ? [.isSelected] : [])
    }

    private func chipForeground(isArmed: Bool, isDisabled: Bool) -> Color {
        if isArmed { return .white }
        return isDisabled ? theme.inkMute : theme.alert
    }

    private func chipBackground(isArmed: Bool, isDisabled: Bool) -> Color {
        if isArmed { return theme.alert }
        return isDisabled ? theme.surfaceLo : theme.alertSoft
    }

    private func chipStroke(isArmed: Bool, isDisabled: Bool) -> Color {
        isDisabled ? theme.line : theme.alert
    }

    /// Tap → toggle one urgent chip. Inserts/removes *every* classifier ID the chip owns
    /// (matters for the combined Emergency sirens chip). Refuses to insert if doing so
    /// would exceed the soft cap — UI also greys out unarmed chips in that state, but we
    /// double-check here in case both fire at once via fast tapping.
    private func toggleUrgent(_ sound: UrgentSound) {
        var set = state.tweaks.armedSounds
        let armed = SoundCatalog.isArmed(sound, in: set)
        if armed {
            for id in sound.classifierIDs { set.remove(id) }
        } else {
            guard armedCount < SoundCatalog.maxUrgent else { return }
            for id in sound.classifierIDs { set.insert(id) }
        }
        state.tweaks.armedSounds = set
    }

    // MARK: - Non-urgent (read-only categorized display)

    private var listeningHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("WHAT WE LISTEN FOR", color: theme.inkSoft)
            Text("Detected sounds appear as a tag in the top-right of the captions screen when \"Show ambient sounds\" is on.")
                .font(.scaled(size: 11, relativeTo: .caption2))
                .foregroundStyle(theme.inkMute)
        }
        .padding(.top, 8)
    }

    private func nonUrgentSection(_ section: SoundCatalog.Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title.uppercased())
                .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                .tracking(1.2)
                .foregroundStyle(theme.inkMute)
                .padding(.top, 4)
            flow(section.sounds) { sound in nonUrgentChip(sound) }
        }
    }

    /// Decorative chip — no tap action. Communicates "the app listens for this" without
    /// implying any selection state.
    private func nonUrgentChip(_ sound: UrgentSound) -> some View {
        HStack(spacing: 6) {
            Image(systemName: sound.icon).font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
            Text(sound.label).font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
        }
        .foregroundStyle(theme.inkSoft)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(theme.surfaceLo))
        .overlay(Capsule().stroke(theme.line, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(sound.label) (auto-detected when ambient tags are on)")
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
            .tracking(1.5)
            .foregroundStyle(color)
    }

    @ViewBuilder
    private func flow<Content: View>(_ items: [UrgentSound], @ViewBuilder content: @escaping (UrgentSound) -> Content) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items) { content($0) }
        }
    }

    // MARK: - About

    private var aboutCard: some View {
        Text("Urgent sounds fire a full-screen alert with haptic. Everything below auto-tags in the corner of the captions screen — turn that on in the captions Adjust sheet. All processing stays on this phone.")
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
