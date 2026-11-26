import SwiftUI
import SwiftData

struct GroveView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]

    @State private var weekAnchor = Date()
    @State private var selectedDay: Date?

    private var week: GroveWeek {
        GroveWeek.build(containing: weekAnchor, sessions: sessions)
    }

    private var selectedBed: GroveDayBed? {
        guard let selectedDay else { return nil }
        return week.beds.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    WeekPlotView(week: week, selectedDay: $selectedDay)
                        .padding(.horizontal, 4)

                    // Week switcher sits under the plot so chevrons aren’t read as “Back”.
                    weekSwitcher

                    if let bed = selectedBed {
                        dayDetail(bed)
                    } else if week.grownCount + week.wiltedCount == 0 {
                        emptyWeek
                    } else {
                        recentStrip
                    }
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(DeskPaperBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Grove")
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(GroveTheme.ink)
                }
            }
        }
    }

    private var weekSwitcher: some View {
        HStack(spacing: 10) {
            Button {
                shiftWeek(by: -1)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.bold))
                    Text("Earlier")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(GroveTheme.mossDeep)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(GroveTheme.chipFill))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Earlier week")

            VStack(spacing: 2) {
                Text(weekTitle)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(GroveTheme.ink)
                    .multilineTextAlignment(.center)
                if Calendar.current.isDate(week.start, equalTo: GroveWeek.weekStart(for: .now), toGranularity: .day) {
                    Text("This week")
                        .font(.caption2)
                        .foregroundStyle(GroveTheme.inkMuted)
                }
            }
            .frame(maxWidth: .infinity)

            Button {
                shiftWeek(by: 1)
            } label: {
                HStack(spacing: 4) {
                    Text("Later")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(GroveTheme.mossDeep)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(GroveTheme.chipFill))
            }
            .buttonStyle(.plain)
            .disabled(isCurrentWeekOrFuture)
            .opacity(isCurrentWeekOrFuture ? 0.35 : 1)
            .accessibilityLabel("Later week")
        }
    }

    private var weekTitle: String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("MMMd")
        let a = f.string(from: week.start)
        let b = f.string(from: week.end)
        return "\(a) – \(b)"
    }

    private var isCurrentWeekOrFuture: Bool {
        let current = GroveWeek.weekStart(for: .now)
        return week.start >= current
    }

    private func shiftWeek(by value: Int) {
        guard let next = Calendar.current.date(byAdding: .weekOfYear, value: value, to: weekAnchor) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            weekAnchor = next
            selectedDay = nil
        }
    }

    private var emptyWeek: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf")
                .font(.title)
                .foregroundStyle(GroveTheme.moss.opacity(0.5))
            Text("This bed is empty")
                .font(.system(.body, design: .serif).weight(.medium))
                .foregroundStyle(GroveTheme.ink)
            Text("Plant a focus session and a tree will appear in today’s plot.")
                .font(.caption)
                .foregroundStyle(GroveTheme.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(GroveTheme.chipFill)
        )
    }

    private var recentStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tap a day to see every tree")
                .font(.caption)
                .foregroundStyle(GroveTheme.inkMuted)

            ForEach(week.beds.filter { !$0.sessions.isEmpty }.reversed().prefix(3)) { bed in
                Button {
                    withAnimation { selectedDay = bed.date }
                } label: {
                    HStack {
                        Text(bed.weekdaySymbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GroveTheme.mossDeep)
                            .frame(width: 36)
                        Text(
                            "\(bed.grown.count) grown · \(bed.wilted.count) wilted · \(bed.focusedMinutes)m"
                        )
                            .font(.subheadline)
                            .foregroundStyle(GroveTheme.ink)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(GroveTheme.inkMuted)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func dayDetail(_ bed: GroveDayBed) -> some View {
        // Newest sessions first.
        let ordered = bed.sessions.sorted { $0.startedAt > $1.startedAt }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dayDetailTitle(bed))
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(GroveTheme.ink)
                Spacer()
                Button("Clear") {
                    withAnimation { selectedDay = nil }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(GroveTheme.moss)
            }

            if ordered.isEmpty {
                Text("No trees planted this day.")
                    .font(.subheadline)
                    .foregroundStyle(GroveTheme.inkMuted)
                    .padding(.vertical, 8)
            } else {
                Text("\(ordered.count) trees · newest on top")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(GroveTheme.inkMuted)

                ForEach(ordered, id: \.id) { session in
                    sessionRow(session)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }

    private func dayDetailTitle(_ bed: GroveDayBed) -> String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("EEEEMMMd")
        return f.string(from: bed.date)
    }

    private func sessionRow(_ session: FocusSession) -> some View {
        HStack(spacing: 12) {
            TreeArt(
                speciesId: session.speciesId,
                progress: session.status == .succeeded ? 0.9 : 0.55,
                wilted: session.status != .succeeded,
                size: .chip
            )
            .frame(width: 40, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(
                    TreeCatalog.species(id: session.speciesId)?.localizedName
                        ?? session.speciesId
                )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GroveTheme.ink)
                Text(sessionSubtitle(session))
                    .font(.caption)
                    .foregroundStyle(GroveTheme.inkMuted)
            }
            Spacer()
            Text(String(localized: "\(session.durationSec / 60)m"))
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(GroveTheme.inkMuted)
        }
        .padding(.vertical, 4)
    }

    private func sessionSubtitle(_ session: FocusSession) -> String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeStyle = .short
        let time = f.string(from: session.startedAt)
        switch session.status {
        case .succeeded:
            return String(localized: "Grown · \(time)")
        case .failed:
            return String(localized: "Wilted · \(time)")
        default:
            return "\(session.status.rawValue) · \(time)"
        }
    }
}
