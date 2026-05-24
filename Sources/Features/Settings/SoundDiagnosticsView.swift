import SwiftUI
import SoundAnalysis

/// Developer screen for verifying that Apple's `SNClassifySoundRequest(.version1)` ships the
/// classifier IDs we hardcoded in `SoundCatalog`. Hardcoded IDs that aren't in the classifier
/// at runtime will never fire detection — so this screen exists for installation-time sanity
/// checks on a physical iPhone (the simulator's classifier matches the host's iOS version,
/// not the deploy target).
///
/// Accessible from Settings → Developer → Sound classifier.
struct SoundDiagnosticsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    @State private var query: String = ""
    /// Resolved lazily on appear so the request init cost (small but nonzero) doesn't
    /// happen until the screen is opened. The classifier's published list is stable per
    /// iOS version, so we capture it once into `@State`.
    @State private var knownIDs: [String] = []

    private var filteredKnown: [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return knownIDs }
        return knownIDs.filter { $0.lowercased().contains(q) }
    }

    /// IDs we wired into `SoundCatalog` that are *not* present in the classifier. These chip
    /// rows in Settings → Sound recognition will stay armable but never fire on this iOS.
    private var missingArmed: [UrgentSound] {
        let known = Set(knownIDs)
        return SoundCatalog.urgent.filter { !known.contains($0.classifierID) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TopBar(
                title: "Sound classifier",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("On-device classifier labels.")
                    .font(.scaled(size: 22, weight: .medium, design: .serif, relativeTo: .title2))
                    .tracking(-0.4)
                    .foregroundStyle(theme.ink)
                Text("\(knownIDs.count) total · this iOS · SNClassifySoundRequest version1")
                    .font(.scaled(size: 12, relativeTo: .caption1))
                    .foregroundStyle(theme.inkMute)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)

            if !missingArmed.isEmpty {
                missingBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            searchField
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredKnown, id: \.self) { id in
                        row(id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { resolveKnownIDs() }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.scaled(size: 13, weight: .semibold, relativeTo: .footnote))
                .foregroundStyle(theme.inkMute)
            TextField("Filter classifier IDs", text: $query)
                .font(.scaled(size: 14, relativeTo: .subheadline))
                .foregroundStyle(theme.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }

    private var missingBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MISSING FROM THIS iOS")
                .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                .tracking(1.5)
                .foregroundStyle(theme.alert)
            Text("These chips are armed in Settings but their classifier IDs aren't in this iOS — detection will never fire for them. Update the IDs in `SoundCatalog.swift`.")
                .font(.scaled(size: 11, relativeTo: .caption2))
                .foregroundStyle(theme.inkSoft)
                .lineSpacing(2)
            ForEach(missingArmed, id: \.classifierID) { sound in
                Text("• \(sound.label) → \(sound.classifierID)")
                    .font(.scaled(size: 11, weight: .semibold, design: .monospaced, relativeTo: .caption2))
                    .foregroundStyle(theme.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.alertSoft)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(theme.alert, lineWidth: 1))
        )
    }

    private func row(_ id: String) -> some View {
        let armed = SoundCatalog.byID[id] != nil
        return HStack(spacing: 8) {
            if armed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.scaled(size: 12, weight: .heavy, relativeTo: .caption1))
                    .foregroundStyle(theme.accent)
            } else {
                Circle()
                    .stroke(theme.line, lineWidth: 1)
                    .frame(width: 12, height: 12)
            }
            Text(id)
                .font(.scaled(size: 12, design: .monospaced, relativeTo: .caption1))
                .foregroundStyle(armed ? theme.ink : theme.inkSoft)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(theme.line.opacity(0.5)), alignment: .bottom)
    }

    private func resolveKnownIDs() {
        guard knownIDs.isEmpty else { return }
        do {
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            knownIDs = request.knownClassifications.sorted()
        } catch {
            knownIDs = []
        }
    }
}
