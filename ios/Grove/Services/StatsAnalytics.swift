import Foundation

enum StatsRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    /// Free tier only gets Week.
    var requiresUnlock: Bool { self != .week }

    var chartTitle: String {
        switch self {
        case .week, .month: return "Daily focus"
        case .year: return "Monthly focus"
        }
    }
}

struct StatsChartPoint: Identifiable, Equatable {
    let id: Date
    let date: Date
    let focusedMinutes: Int
    let grownCount: Int
    let wiltedCount: Int
}

struct SpeciesStat: Identifiable, Equatable {
    let id: String
    let name: String
    let grownCount: Int
    let focusedMinutes: Int
}

struct StatsSnapshot {
    let range: StatsRange
    let points: [StatsChartPoint]
    let focusedMinutes: Int
    let grownCount: Int
    let wiltedCount: Int
    let streakDays: Int
    let species: [SpeciesStat]

    var successRate: Double {
        let total = grownCount + wiltedCount
        guard total > 0 else { return 0 }
        return Double(grownCount) / Double(total)
    }
}

enum StatsAnalytics {
    static func snapshot(
        sessions: [FocusSession],
        range: StatsRange,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> StatsSnapshot {
        let cal = calendar
        let today = cal.startOfDay(for: now)
        let streakValue = streak(sessions: sessions, now: now, calendar: cal)

        switch range {
        case .week:
            return buildDaily(
                sessions: sessions,
                dayCount: 7,
                range: range,
                today: today,
                calendar: cal,
                streakDays: streakValue
            )
        case .month:
            return buildDaily(
                sessions: sessions,
                dayCount: 30,
                range: range,
                today: today,
                calendar: cal,
                streakDays: streakValue
            )
        case .year:
            return buildMonthly(
                sessions: sessions,
                monthCount: 12,
                range: range,
                today: today,
                calendar: cal,
                streakDays: streakValue
            )
        }
    }

    // MARK: - Daily (week / month)

    private static func buildDaily(
        sessions: [FocusSession],
        dayCount: Int,
        range: StatsRange,
        today: Date,
        calendar cal: Calendar,
        streakDays: Int
    ) -> StatsSnapshot {
        guard let start = cal.date(byAdding: .day, value: -(dayCount - 1), to: today) else {
            return empty(range: range, streakDays: streakDays)
        }

        let window = sessions.filter {
            $0.startedAt >= start && $0.status != .running && $0.status != .cancelled
        }

        var points: [StatsChartPoint] = []
        for offset in 0..<dayCount {
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { continue }
            let dayStart = cal.startOfDay(for: day)
            guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            let daySessions = window.filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
            points.append(point(from: daySessions, date: dayStart))
        }

        return assemble(range: range, points: points, window: window, streakDays: streakDays)
    }

    // MARK: - Monthly (year)

    private static func buildMonthly(
        sessions: [FocusSession],
        monthCount: Int,
        range: StatsRange,
        today: Date,
        calendar cal: Calendar,
        streakDays: Int
    ) -> StatsSnapshot {
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today
        guard let start = cal.date(byAdding: .month, value: -(monthCount - 1), to: monthStart) else {
            return empty(range: range, streakDays: streakDays)
        }

        let window = sessions.filter {
            $0.startedAt >= start && $0.status != .running && $0.status != .cancelled
        }

        var points: [StatsChartPoint] = []
        for offset in 0..<monthCount {
            guard let month = cal.date(byAdding: .month, value: offset, to: start) else { continue }
            let mStart = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
            guard let mEnd = cal.date(byAdding: .month, value: 1, to: mStart) else { continue }
            let monthSessions = window.filter { $0.startedAt >= mStart && $0.startedAt < mEnd }
            points.append(point(from: monthSessions, date: mStart))
        }

        return assemble(range: range, points: points, window: window, streakDays: streakDays)
    }

    // MARK: - Helpers

    private static func point(from daySessions: [FocusSession], date: Date) -> StatsChartPoint {
        let grown = daySessions.filter { $0.status == .succeeded }
        let wilted = daySessions.filter { $0.status == .failed || $0.wilted }
        let sec = grown.reduce(0) { $0 + $1.durationSec }
        let minutes = sec > 0 ? max(1, Int(ceil(Double(sec) / 60.0))) : 0
        return StatsChartPoint(
            id: date,
            date: date,
            focusedMinutes: minutes,
            grownCount: grown.count,
            wiltedCount: wilted.count
        )
    }

    private static func assemble(
        range: StatsRange,
        points: [StatsChartPoint],
        window: [FocusSession],
        streakDays: Int
    ) -> StatsSnapshot {
        let grownCount = points.reduce(0) { $0 + $1.grownCount }
        let wiltedCount = points.reduce(0) { $0 + $1.wiltedCount }
        let focusedMinutes = points.reduce(0) { $0 + $1.focusedMinutes }
        return StatsSnapshot(
            range: range,
            points: points,
            focusedMinutes: focusedMinutes,
            grownCount: grownCount,
            wiltedCount: wiltedCount,
            streakDays: streakDays,
            species: speciesBreakdown(window: window)
        )
    }

    private static func speciesBreakdown(window: [FocusSession]) -> [SpeciesStat] {
        let grown = window.filter { $0.status == .succeeded }
        var map: [String: (count: Int, sec: Int)] = [:]
        for session in grown {
            var entry = map[session.speciesId] ?? (0, 0)
            entry.count += 1
            entry.sec += session.durationSec
            map[session.speciesId] = entry
        }

        return map.map { id, value in
            let name = TreeCatalog.species(id: id)?.name ?? id.capitalized
            let minutes = value.sec > 0 ? max(1, Int(ceil(Double(value.sec) / 60.0))) : 0
            return SpeciesStat(id: id, name: name, grownCount: value.count, focusedMinutes: minutes)
        }
        .sorted { lhs, rhs in
            if lhs.grownCount != rhs.grownCount { return lhs.grownCount > rhs.grownCount }
            return lhs.focusedMinutes > rhs.focusedMinutes
        }
    }

    private static func empty(range: StatsRange, streakDays: Int) -> StatsSnapshot {
        StatsSnapshot(
            range: range,
            points: [],
            focusedMinutes: 0,
            grownCount: 0,
            wiltedCount: 0,
            streakDays: streakDays,
            species: []
        )
    }

    /// Consecutive calendar days (ending today or yesterday) with ≥1 grown tree.
    static func streak(
        sessions: [FocusSession],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let cal = calendar
        let grownDays: Set<Date> = Set(
            sessions
                .filter { $0.status == .succeeded }
                .map { cal.startOfDay(for: $0.startedAt) }
        )
        guard !grownDays.isEmpty else { return 0 }

        let today = cal.startOfDay(for: now)
        var cursor = today
        if !grownDays.contains(today),
           let yesterday = cal.date(byAdding: .day, value: -1, to: today),
           grownDays.contains(yesterday) {
            cursor = yesterday
        } else if !grownDays.contains(today) {
            return 0
        }

        var count = 0
        while grownDays.contains(cursor) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }
}
