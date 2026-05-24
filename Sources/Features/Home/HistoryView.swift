import SwiftUI
import SwiftData

/// All saved conversations, grouped by day. Reads live from SwiftData via `@Query` so a new
/// conversation appears the moment you return from a Live session.
///
/// Build-15: rows now support swipe actions. Swipe **left** (trailing edge) → delete (no
/// confirmation, follows the Mail / Messages convention; cascade-deletes the lines +
/// detections via the SwiftData relationship). Swipe **right** (leading edge) → opens the
/// system share sheet with a plain-text export of the transcript (Notes, Files, Drive if
/// installed, iMessage, Mail).
struct HistoryView: View {
    @Environment(AppState.self) private var state
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case oneToOne = "1:1"
        case group = "Group"
        case starred = "Starred"
        case withAlerts = "With alerts"
        var id: String { rawValue }
    }

    @State private var filter: Filter = .all
    /// Drives the share sheet — set by the leading swipe action.
    @State private var shareTarget: ShareTarget?

    /// Sheet-identifying wrapper so SwiftUI's `.sheet(item:)` can present the activity
    /// view controller. Holds the prerendered text so the SwiftData record isn't accessed
    /// after a possible delete.
    struct ShareTarget: Identifiable {
        let id: UUID
        let text: String
        let subject: String
    }

    @Query(
        sort: [SortDescriptor(\ConversationRecord.startedAt, order: .reverse)]
    ) private var conversations: [ConversationRecord]

    private var filteredConversations: [ConversationRecord] {
        conversations.filter { conv in
            guard !conv.lines.isEmpty else { return false }
            switch filter {
            case .all: return true
            case .oneToOne: return conv.mode == .oneToOne
            case .group: return conv.mode == .group
            case .starred: return conv.isStarred
            case .withAlerts: return conv.hadUrgentDetection
            }
        }
    }

    /// In-memory day grouping. Cheap at the sizes we expect (dozens of conversations).
    private struct DayGroup: Identifiable {
        let id: Date
        let label: String
        let items: [ConversationRecord]
    }

    private var groups: [DayGroup] {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: filteredConversations) { conv in
            cal.startOfDay(for: conv.startedAt)
        }
        return byDay.keys.sorted(by: >).map { day in
            DayGroup(id: day, label: Self.dayLabel(day), items: byDay[day]!)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TopBar(
                title: "Transcripts",
                left: { IconButton(systemName: "chevron.left", action: { state.path.removeLast() }, color: theme.inkSoft, accessibilityLabel: "Back") }
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(headlineText)
                    .font(.scaled(size: 32, weight: .medium, design: .serif, relativeTo: .largeTitle))
                    .tracking(-1)
                    .foregroundStyle(theme.ink)
                Text("Swipe left to delete, right to share. Nothing leaves your device.")
                    .font(.scaled(size: 12, relativeTo: .caption1))
                    .foregroundStyle(theme.inkMute)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 4)

            filterChips

            if groups.isEmpty {
                emptyState
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                Spacer()
            } else {
                conversationList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $shareTarget) { target in
            // System share sheet — Notes, Files, Mail, Messages, Drive, etc.
            ShareSheet(items: [target.text], subject: target.subject)
        }
    }

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Filter.allCases) { f in
                    Button { filter = f } label: {
                        Text(f.rawValue)
                            .font(.scaled(size: 12, weight: .semibold, relativeTo: .caption1))
                            .foregroundStyle(filter == f ? theme.onAccent : theme.inkSoft)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(filter == f ? theme.accent : theme.surface))
                            .overlay(Capsule().stroke(theme.line, lineWidth: filter == f ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Conversation list

    /// SwiftUI `List` is required for `.swipeActions` to work. We strip the default
    /// styling (`.plain` listStyle + hidden scroll background + cleared row backgrounds /
    /// separators) so the existing card-style rows render as before.
    private var conversationList: some View {
        List {
            ForEach(groups) { g in
                Section {
                    ForEach(g.items, id: \.id) { conv in
                        row(conv)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            // Swipe left → trailing edge → destructive delete. iOS Mail
                            // convention: no confirmation; user can recover by recording
                            // again. Cascade-delete cleans up lines + detections.
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteConversation(conv)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            // Swipe right → leading edge → share sheet. Pre-renders the
                            // plain-text export so the SwiftData object isn't touched after
                            // sheet present (avoids access-after-delete in edge cases).
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    shareTarget = ShareTarget(
                                        id: conv.id,
                                        text: conv.plainTextExport,
                                        subject: "Earshot — \(HomeView.titleFor(conv))"
                                    )
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(theme.accent)
                            }
                    }
                } header: {
                    Text(g.label)
                        .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                        .tracking(1.5)
                        .foregroundStyle(theme.inkMute)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.bg)
    }

    private func deleteConversation(_ conv: ConversationRecord) {
        modelContext.delete(conv)
        try? modelContext.save()
    }

    // MARK: - Empty / header

    private var headlineText: String {
        let n = filteredConversations.count
        return "\(n) conversation\(n == 1 ? "" : "s")"
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(filter == .all ? "Nothing yet." : "No conversations match this filter.")
                .font(.scaled(size: 16, weight: .semibold, design: .serif, relativeTo: .body))
                .foregroundStyle(theme.inkSoft)
            Text(filter == .all
                 ? "Your conversations will collect here as you use the app."
                 : "Try \"All\" to see everything saved.")
                .font(.scaled(size: 12, relativeTo: .caption1))
                .foregroundStyle(theme.inkMute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(theme.line, lineWidth: 1))
        )
    }

    // MARK: - Row

    private func row(_ conv: ConversationRecord) -> some View {
        Button { state.push(.summary(conv.id)) } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(HomeView.titleFor(conv))
                            .font(.scaled(size: 15, weight: .semibold, relativeTo: .subheadline))
                            .foregroundStyle(theme.ink)
                        Text(HomeView.metaFor(conv))
                            .font(.scaled(size: 11, relativeTo: .caption2))
                            .foregroundStyle(theme.inkMute)
                    }
                    Spacer(minLength: 0)
                    if conv.isStarred {
                        Image(systemName: "star.fill")
                            .font(.scaled(size: 12, weight: .heavy, relativeTo: .caption1))
                            .foregroundStyle(theme.accent)
                    }
                    speakerStack(for: conv)
                }
                if conv.hadUrgentDetection, let det = conv.detections.first {
                    HStack(spacing: 5) {
                        Image(systemName: det.icon)
                            .font(.scaled(size: 11, weight: .heavy, relativeTo: .caption2))
                        Text("\(det.label.lowercased()) detected")
                            .font(.scaled(size: 11, weight: .semibold, relativeTo: .caption2))
                    }
                    .foregroundStyle(theme.alert)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Capsule().fill(theme.alertSoft))
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(conv.hadUrgentDetection ? theme.alertSoft : theme.line, lineWidth: 1)
            )
            .overlay(
                Rectangle()
                    .fill(conv.hadUrgentDetection ? theme.alert : Color.clear)
                    .frame(width: conv.hadUrgentDetection ? 4 : 0)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)),
                alignment: .leading
            )
        }
        .buttonStyle(.plain)
    }

    /// Stacked speaker initials (max 4). Empty for single-speaker rows.
    @ViewBuilder
    private func speakerStack(for conv: ConversationRecord) -> some View {
        let uniqueSpeakers = Array(Dictionary(grouping: conv.lines, by: \.speakerId).keys.prefix(4))
        if uniqueSpeakers.count > 1 {
            HStack(spacing: -6) {
                ForEach(Array(uniqueSpeakers.enumerated()), id: \.offset) { idx, id in
                    let line = conv.lines.first(where: { $0.speakerId == id })
                    let initial = line?.speakerInitial ?? "·"
                    let color = (line?.speaker.color(in: theme)) ?? theme.spkA
                    Text(initial)
                        .font(.scaled(size: 10, weight: .heavy, relativeTo: .caption2))
                        .foregroundStyle(theme.bg)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(color))
                        .overlay(Circle().stroke(theme.surface, lineWidth: 2))
                        .zIndex(Double(4 - idx))
                }
            }
        }
    }

    private static func dayLabel(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "TODAY" }
        if cal.isDateInYesterday(day) { return "YESTERDAY" }
        let f = DateFormatter()
        f.dateFormat = "EEE · MMM d"
        return f.string(from: day).uppercased()
    }
}
