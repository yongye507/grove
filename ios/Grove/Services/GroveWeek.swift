import Foundation

struct GroveDayBed: Identifiable {
    let id: Date // start of day
    let date: Date
    let sessions: [FocusSession]

    var weekdaySymbol: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    var grown: [FocusSession] { sessions.filter { $0.status == .succeeded } }
    var wilted: [FocusSession] { sessions.filter { $0.status == .failed || $0.wilted } }
    var focusedMinutes: Int {
        let sec = grown.reduce(0) { $0 + $1.durationSec }
        guard sec > 0 else { return 0 }
        return max(1, Int(ceil(Double(sec) / 60.0)))
    }
}

struct GroveWeek: Identifiable {
    let id: Date // week start
    let start: Date
    let end: Date
    let beds: [GroveDayBed]

    var title: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let startText = f.string(from: start)
        f.dateFormat = "MMM d, yyyy"
        let endText = f.string(from: end)
        return "\(startText) – \(endText)"
    }

    var grownCount: Int { beds.reduce(0) { $0 + $1.grown.count } }
    var wiltedCount: Int { beds.reduce(0) { $0 + $1.wilted.count } }
    var focusedMinutes: Int { beds.reduce(0) { $0 + $1.focusedMinutes } }

    static func weekStart(for date: Date, calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? cal.startOfDay(for: date)
    }

    static func build(
        containing date: Date,
        sessions: [FocusSession],
        calendar: Calendar = .current
    ) -> GroveWeek {
        var cal = calendar
        cal.firstWeekday = 2
        let start = weekStart(for: date, calendar: cal)
        let end = cal.date(byAdding: .day, value: 6, to: start) ?? start

        let beds: [GroveDayBed] = (0..<7).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let dayStart = cal.startOfDay(for: day)
            let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let daySessions = sessions
                .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                .filter { $0.status != .running && $0.status != .cancelled }
                .sorted { $0.startedAt > $1.startedAt } // newest first
            return GroveDayBed(id: dayStart, date: dayStart, sessions: daySessions)
        }

        return GroveWeek(id: start, start: start, end: end, beds: beds)
    }
}
