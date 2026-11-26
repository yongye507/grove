import SwiftUI

/// Top-down “一周一畦” — same pot-tree art as Plant page, with an explicit legend.
struct WeekPlotView: View {
    let week: GroveWeek
    @Binding var selectedDay: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            legend

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "6B5344"), Color(hex: "5A4638")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 6)

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "8B7355"), Color(hex: "7A6248")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(10)

                HStack(spacing: 5) {
                    ForEach(week.beds) { bed in
                        DayPlotCell(
                            bed: bed,
                            isSelected: isSameDay(bed.date, selectedDay),
                            isToday: Calendar.current.isDateInToday(bed.date)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isSameDay(bed.date, selectedDay) {
                                    selectedDay = nil
                                } else {
                                    selectedDay = bed.date
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
            }
            .frame(height: 228)

            HStack(spacing: 16) {
                stat("Grown", value: "\(week.grownCount)")
                stat("Wilted", value: "\(week.wiltedCount)")
                stat("Focus", value: "\(week.focusedMinutes)m")
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(wilted: false, title: "Grown — finished focus")
            legendItem(wilted: true, title: "Wilted — left early")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
    }

    private func legendItem(wilted: Bool, title: String) -> some View {
        HStack(spacing: 6) {
            TreeArt(speciesId: "oak", progress: wilted ? 0.55 : 0.85, wilted: wilted, size: .chip)
                .frame(width: 28, height: 32)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(GroveTheme.inkMuted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(GroveTheme.inkMuted)
            Text(value)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(GroveTheme.ink)
        }
    }

    private func isSameDay(_ a: Date, _ b: Date?) -> Bool {
        guard let b else { return false }
        return Calendar.current.isDate(a, inSameDayAs: b)
    }
}

private struct DayPlotCell: View {
    let bed: GroveDayBed
    let isSelected: Bool
    let isToday: Bool

    /// Newest first — same order as day detail.
    private var allTrees: [FocusSession] {
        bed.sessions.sorted { $0.startedAt > $1.startedAt }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(bed.weekdaySymbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isToday ? GroveTheme.leafLight : Color.white.opacity(0.75))

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "5C4033").opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isSelected ? GroveTheme.leafLight : Color.white.opacity(0.12),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                if allTrees.isEmpty {
                    Text("empty")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .frame(maxHeight: .infinity)
                } else {
                    VStack(spacing: 4) {
                        // Total count for the day (not “+N more”).
                        Text("\(allTrees.count)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(GroveTheme.leafLight)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.black.opacity(0.28)))
                            .padding(.top, 5)

                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 2) {
                                ForEach(allTrees, id: \.id) { session in
                                    TreeArt(
                                        speciesId: session.speciesId,
                                        progress: session.status == .succeeded ? 0.92 : 0.55,
                                        wilted: session.status != .succeeded,
                                        size: .chip
                                    )
                                    .frame(width: 22, height: 32)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.bottom, 4)
                        }
                        // Nested scroll inside the week ScrollView.
                        .scrollBounceBehavior(.basedOnSize)
                    }
                    .padding(.horizontal, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 132)

            Text(bed.dayNumber)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bed.weekdaySymbol) \(allTrees.count) trees")
        .accessibilityHint(allTrees.count > 3 ? "Scroll inside the bed, or tap for the full list" : "Tap for details")
    }
}
