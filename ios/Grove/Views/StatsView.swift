import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [FocusSession]
    @Query private var settingsRows: [AppSettings]
    var store: StoreService

    @State private var showPaywall = false
    @State private var range: StatsRange = .week

    private var unlocked: Bool {
        settingsRows.first?.lifetimeUnlocked == true || store.hasLifetimeEntitlement
    }

    private var snapshot: StatsSnapshot {
        StatsAnalytics.snapshot(sessions: sessions, range: range)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    rangePicker

                    summaryRow

                    minutesChartCard

                    grownWiltedCard

                    speciesCard

                    unlockCard
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(DeskPaperBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Stats")
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(GroveTheme.ink)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: store) {
                    settingsRows.first?.lifetimeUnlocked = true
                    try? modelContext.save()
                    showPaywall = false
                }
            }
            .onChange(of: store.hasLifetimeEntitlement) { _, value in
                if value {
                    settingsRows.first?.lifetimeUnlocked = true
                    try? modelContext.save()
                }
            }
            .onChange(of: unlocked) { _, isOn in
                if !isOn, range.requiresUnlock {
                    range = .week
                }
            }
        }
    }

    // MARK: - Range

    private var rangePicker: some View {
        HStack(spacing: 8) {
            ForEach(StatsRange.allCases) { item in
                let locked = item.requiresUnlock && !unlocked
                Button {
                    if locked {
                        showPaywall = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) { range = item }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(item.title)
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9))
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(range == item && !locked ? .white : GroveTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(range == item && !locked ? GroveTheme.mossDeep : GroveTheme.chipFill)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: 10) {
            summaryTile(
                title: String(localized: "Focus"),
                value: String(localized: "\(snapshot.focusedMinutes)m"),
                subtitle: range.title
            )
            summaryTile(
                title: String(localized: "Grown"),
                value: "\(snapshot.grownCount)",
                subtitle: String(localized: "trees")
            )
            summaryTile(
                title: String(localized: "Streak"),
                value: "\(snapshot.streakDays)",
                subtitle: snapshot.streakDays == 1
                    ? String(localized: "day")
                    : String(localized: "days")
            )
        }
    }

    private func summaryTile(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(GroveTheme.inkMuted)
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(GroveTheme.ink)
                .monospacedDigit()
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(GroveTheme.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
    }

    // MARK: - Focus chart

    private var minutesChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(range.chartTitle)
                    .font(.system(.body, design: .serif).weight(.semibold))
                    .foregroundStyle(GroveTheme.ink)
                Spacer()
                Text("minutes")
                    .font(.caption)
                    .foregroundStyle(GroveTheme.inkMuted)
            }

            if snapshot.points.allSatisfy({ $0.focusedMinutes == 0 }) {
                Text("No grown trees in this range yet.\nFinish a session to see the chart.")
                    .font(.subheadline)
                    .foregroundStyle(GroveTheme.inkMuted)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 28)
            } else {
                Chart(snapshot.points) { point in
                    BarMark(
                        x: .value(
                            range == .year
                                ? String(localized: "Month")
                                : String(localized: "Day"),
                            point.date,
                            unit: range == .year ? .month : .day
                        ),
                        y: .value(String(localized: "Minutes"), point.focusedMinutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GroveTheme.leafLight, GroveTheme.mossDeep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(range == .year ? 5 : 3)
                }
                .chartXAxis {
                    AxisMarks(values: axisValues) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(axisLabel(date))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(GroveTheme.inkMuted)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(GroveTheme.ink.opacity(0.12))
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(GroveTheme.inkMuted)
                    }
                }
                .frame(height: 168)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }

    private var axisValues: AxisMarkValues {
        switch range {
        case .week:
            return .stride(by: .day, count: 1)
        case .month:
            return .stride(by: .day, count: 5)
        case .year:
            return .stride(by: .month, count: 1)
        }
    }

    // MARK: - Grown vs wilted

    private var grownWiltedCard: some View {
        let grown = snapshot.grownCount
        let wilted = snapshot.wiltedCount
        let total = max(grown + wilted, 1)
        let grownShare = CGFloat(grown) / CGFloat(total)
        let wiltedShare = CGFloat(wilted) / CGFloat(total)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Grown vs wilted")
                .font(.system(.body, design: .serif).weight(.semibold))
                .foregroundStyle(GroveTheme.ink)

            GeometryReader { geo in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(GroveTheme.moss)
                        .frame(width: max(grown == 0 ? 0 : geo.size.width * grownShare, grown > 0 ? 8 : 0))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(GroveTheme.wiltLeaf)
                        .frame(width: max(wilted == 0 ? 0 : geo.size.width * wiltedShare, wilted > 0 ? 8 : 0))
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 14)

            HStack {
                legendDot(color: GroveTheme.moss, title: String(localized: "Grown"), value: "\(grown)")
                Spacer()
                legendDot(color: GroveTheme.wiltLeaf, title: String(localized: "Wilted"), value: "\(wilted)")
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Stay rate")
                        .font(.caption2)
                        .foregroundStyle(GroveTheme.inkMuted)
                    Text(String(format: "%.0f%%", snapshot.successRate * 100))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(GroveTheme.ink)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }

    private func legendDot(color: Color, title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(GroveTheme.inkMuted)
                Text(value)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(GroveTheme.ink)
            }
        }
    }

    // MARK: - Species

    private var speciesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trees by species")
                .font(.system(.body, design: .serif).weight(.semibold))
                .foregroundStyle(GroveTheme.ink)

            if snapshot.species.isEmpty {
                Text("Grown trees in this range will show up here by species.")
                    .font(.subheadline)
                    .foregroundStyle(GroveTheme.inkMuted)
                    .padding(.vertical, 8)
            } else {
                let maxCount = max(snapshot.species.map(\.grownCount).max() ?? 1, 1)
                ForEach(snapshot.species) { item in
                    HStack(spacing: 10) {
                        TreeArt(
                            speciesId: item.id,
                            progress: 0.85,
                            wilted: false,
                            size: .chip
                        )
                        .frame(width: 28, height: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(String(localized: String.LocalizationValue(item.name)))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(GroveTheme.ink)
                                Spacer()
                                Text(String(localized: "\(item.grownCount) · \(item.focusedMinutes)m"))
                                    .font(.caption.monospacedDigit().weight(.medium))
                                    .foregroundStyle(GroveTheme.inkMuted)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(GroveTheme.ink.opacity(0.08))
                                    Capsule()
                                        .fill(GroveTheme.moss.opacity(0.85))
                                        .frame(
                                            width: geo.size.width
                                                * CGFloat(item.grownCount)
                                                / CGFloat(maxCount)
                                        )
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }

    // MARK: - Unlock

    @ViewBuilder
    private var unlockCard: some View {
        if !unlocked {
            VStack(alignment: .leading, spacing: 10) {
                Text("Lifetime")
                    .font(.system(.body, design: .serif).weight(.semibold))
                    .foregroundStyle(GroveTheme.ink)
                Text("Free stats cover the last 7 days. Unlock Month & Year charts, full history, and every tree species.")
                    .font(.caption)
                    .foregroundStyle(GroveTheme.inkMuted)
                Button {
                    showPaywall = true
                } label: {
                    Text("Unlock Lifetime")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(GroveTheme.mossDeep)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.55))
            )
        } else {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(GroveTheme.moss)
                Text("Lifetime unlocked — full history")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(GroveTheme.ink)
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.45))
            )
        }
    }

    // MARK: - Format

    private func axisLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        switch range {
        case .week:
            f.setLocalizedDateFormatFromTemplate("EEE")
            let s = f.string(from: date)
            return String(s.prefix(1))
        case .month:
            f.setLocalizedDateFormatFromTemplate("d")
            return f.string(from: date)
        case .year:
            f.setLocalizedDateFormatFromTemplate("MMM")
            let s = f.string(from: date)
            return String(s.prefix(1))
        }
    }
}
