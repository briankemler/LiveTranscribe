import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme

    /// Most recent conversations with at least one line. `@Query` re-fires whenever the
    /// store changes — so finishing a session and popping back to Home shows the new entry
    /// without manual refresh. Build-15: uncap the list and let the recents region scroll
    /// inside its allocated flex space, so users with many recent conversations don't
    /// hit an artificial 3-item ceiling. "See all" still pushes to HistoryView for filters.
    @Query(
        sort: [SortDescriptor(\ConversationRecord.startedAt, order: .reverse)]
    ) private var recents: [ConversationRecord]

    private var visibleRecents: [ConversationRecord] {
        recents.filter { !$0.lines.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TopBar(
                left: { kickerLogo },
                right: { IconButton(systemName: "gearshape", action: { state.push(.settings) }, color: theme.inkSoft, accessibilityLabel: "Settings") }
            )

            VStack(alignment: .leading, spacing: 0) {
                AccentItalicTitle(lead: "Ready when", accentLine: "you are.", size: 44, tracking: -1.6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 16)

            startCard
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            modeRow
                .padding(.horizontal, 16)
                .padding(.bottom, 18)

            // Recents fills the remaining space between the mode row and the footer.
            // List of conversations scrolls; the "RECENT" header stays pinned at the top.
            recentList
                .padding(.horizontal, 16)
                .frame(maxHeight: .infinity, alignment: .top)

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var kickerLogo: some View {
        Text("EARSHOT")
            .font(.scaled(size: 12, weight: .heavy, relativeTo: .caption1))
            .tracking(2)
            .foregroundStyle(theme.accent)
            .padding(.leading, 8)
    }

    private var startCard: some View {
        Button {
            state.startLive(.oneToOne)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(theme.accent).frame(width: 56, height: 56)
                    Image(systemName: "mic.fill")
                        .font(.scaled(size: 26, weight: .heavy, relativeTo: .title1))
                        .foregroundStyle(theme.onAccent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Start listening")
                        .font(.scaled(size: 19, weight: .bold, relativeTo: .title3))
                        .tracking(-0.2)
                        .foregroundStyle(theme.ink)
                    Text("Auto-detect speakers · 5 urgent sounds")
                        .font(.scaled(size: 12, relativeTo: .caption1))
                        .foregroundStyle(theme.inkSoft)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.scaled(size: 18, weight: .bold, relativeTo: .title3))
                    .foregroundStyle(theme.ink)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.surfaceHi)
            )
            .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var modeRow: some View {
        HStack(spacing: 10) {
            modeCard(icon: "person.fill", title: "1:1", sub: "two voices") { state.startLive(.oneToOne) }
            modeCard(icon: "person.3.fill", title: "Group", sub: "3+ voices") { state.startLive(.group) }
        }
    }

    private func modeCard(icon: String, title: String, sub: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: icon)
                    .font(.scaled(size: 18, weight: .semibold, relativeTo: .title3))
                    .foregroundStyle(theme.accent)
                Spacer().frame(height: 8)
                Text(title)
                    .font(.scaled(size: 14, weight: .bold, relativeTo: .subheadline))
                    .foregroundStyle(theme.ink)
                Spacer().frame(height: 1)
                Text(sub)
                    .font(.scaled(size: 11, relativeTo: .caption2))
                    .foregroundStyle(theme.inkMute)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(theme.line, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var recentList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RECENT")
                    .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                    .tracking(1.5)
                    .foregroundStyle(theme.inkMute)
                Spacer()
                if !visibleRecents.isEmpty {
                    Button { state.push(.history) } label: {
                        Text("See all →")
                            .font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
                            .foregroundStyle(theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 2)

            if visibleRecents.isEmpty {
                emptyState
            } else {
                // Scroll-clip the rows so the section can hold every conversation that has
                // ever been saved without pushing the footer offscreen. `LazyVStack` keeps
                // the row-render cost proportional to what's visible.
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(visibleRecents, id: \.id) { conv in
                            Button { state.push(.summary(conv.id)) } label: { recentRow(conv) }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.never)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nothing yet.")
                .font(.scaled(size: 14, weight: .semibold, design: .serif, relativeTo: .subheadline))
                .foregroundStyle(theme.inkSoft)
            Text("Tap Start listening — your conversations will collect here.")
                .font(.scaled(size: 12, relativeTo: .caption1))
                .foregroundStyle(theme.inkMute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }

    private func recentRow(_ conv: ConversationRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.titleFor(conv)).font(.scaled(size: 14, weight: .semibold, relativeTo: .subheadline)).foregroundStyle(theme.ink)
                Text(Self.metaFor(conv)).font(.scaled(size: 11, relativeTo: .caption2)).foregroundStyle(theme.inkMute)
            }
            Spacer(minLength: 0)
            if conv.hadUrgentDetection {
                Text("ALERT")
                    .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                    .tracking(0.5)
                    .foregroundStyle(theme.alert)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule().fill(theme.alertSoft))
            }
            Image(systemName: "arrow.right")
                .font(.scaled(size: 14, weight: .semibold, relativeTo: .subheadline))
                .foregroundStyle(theme.inkMute)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "cpu")
                .font(.scaled(size: 12, weight: .heavy, relativeTo: .caption1))
                .foregroundStyle(theme.accent)
            Text("On-device · nothing leaves your phone")
                .font(.scaled(size: 11, relativeTo: .caption2))
                .foregroundStyle(theme.inkMute)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle().frame(height: 1).foregroundStyle(theme.line),
            alignment: .top
        )
        .padding(.top, 12)
    }

    // MARK: - Formatting helpers (nonisolated so the share-sheet exporter can use them)

    /// Title is `"Today · 2:34 PM"` for sessions started today; calendar-relative ("Yesterday")
    /// for the day before; and `"May 8 · 2:34 PM"` further back.
    /// Builds a fresh `DateFormatter` per call — keeps the function isolation-clean for
    /// callers like `ConversationExport`. Negligible overhead at the call rates we see.
    nonisolated static func titleFor(_ conv: ConversationRecord) -> String {
        let cal = Calendar.current
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "h:mm a"
        let dayPart: String
        if cal.isDateInToday(conv.startedAt) {
            dayPart = "Today"
        } else if cal.isDateInYesterday(conv.startedAt) {
            dayPart = "Yesterday"
        } else {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            dayPart = f.string(from: conv.startedAt)
        }
        return "\(dayPart) · \(timeFmt.string(from: conv.startedAt))"
    }

    /// Metadata strip below the title: duration + voice count.
    nonisolated static func metaFor(_ conv: ConversationRecord) -> String {
        let mins = Int(conv.duration / 60)
        let secs = Int(conv.duration) % 60
        let durStr: String = mins > 0 ? "\(mins)m" : "\(secs)s"
        let voices = conv.speakerCount
        let mode = conv.mode == .group ? "Group" : "1:1"
        if voices > 0 {
            return "\(mode) · \(durStr) · \(voices) voice\(voices == 1 ? "" : "s")"
        }
        return "\(mode) · \(durStr)"
    }
}
