import Foundation

/// Computes "emendas" — the days off you get by bridging a holiday with the
/// nearest weekend(s), and how many vacation days that bridge costs.
enum EmendaCalculator {
    struct Bridge {
        let start: Date
        let end: Date
        let vacationDays: Int
        let totalDays: Int
    }

    /// Bridges a holiday to the nearest weekend. When the holiday already sits
    /// next to a weekend (Monday or Friday), it bridges the whole adjacent work
    /// week instead so the emenda connects both weekends.
    static func bridge(for holiday: Date, calendar: Calendar) -> Bridge {
        let weekday = calendar.component(.weekday, from: holiday) // Sun=1 ... Sat=7
        let daysToPrevSaturday = (weekday - 7 + 7) % 7
        let daysToNextSunday = (1 - weekday + 7) % 7
        let prevSaturday = calendar.date(byAdding: .day, value: -daysToPrevSaturday, to: holiday)!
        let nextSunday = calendar.date(byAdding: .day, value: daysToNextSunday, to: holiday)!

        let backGap = max(0, daysToPrevSaturday - 2)
        let forwardGap = max(0, daysToNextSunday - 2)

        let start: Date
        let end: Date
        let vacationDays: Int
        if backGap == 0 || forwardGap == 0 {
            start = prevSaturday
            end = nextSunday
            vacationDays = max(backGap, forwardGap)
        } else if backGap < forwardGap {
            start = prevSaturday
            end = holiday
            vacationDays = backGap
        } else {
            start = holiday
            end = nextSunday
            vacationDays = forwardGap
        }

        let totalDays = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        return Bridge(start: start, end: end, vacationDays: vacationDays, totalDays: totalDays)
    }

    /// Builds an `Emenda` for the given holiday, or `nil` if the holiday already
    /// falls on a weekend or requires no vacation days to bridge.
    static func makeEmenda(name: String, date: Date, isNational: Bool, ufCode: String, calendar: Calendar) -> Emenda? {
        let weekday = calendar.component(.weekday, from: date)
        guard weekday != 1, weekday != 7 else { return nil }

        let bridge = bridge(for: date, calendar: calendar)
        guard bridge.vacationDays > 0 else { return nil }

        let monthFmt = DateFormatter()
        monthFmt.locale = Locale(identifier: "pt_BR")
        monthFmt.dateFormat = "MMM"

        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "dd"

        let weekdayFmt = DateFormatter()
        weekdayFmt.locale = Locale(identifier: "pt_BR")
        weekdayFmt.dateFormat = "EEEE"

        let range: String
        if calendar.isDate(bridge.start, equalTo: bridge.end, toGranularity: .month) {
            range = "\(dayFmt.string(from: bridge.start))–\(dayFmt.string(from: bridge.end)) \(monthFmt.string(from: bridge.end).capitalized)"
        } else {
            range = "\(dayFmt.string(from: bridge.start)) \(monthFmt.string(from: bridge.start).capitalized) – \(dayFmt.string(from: bridge.end)) \(monthFmt.string(from: bridge.end).capitalized)"
        }

        return Emenda(
            date: date,
            month: monthFmt.string(from: date).uppercased(),
            day: dayFmt.string(from: date),
            name: name,
            weekday: weekdayFmt.string(from: date).capitalized,
            range: range,
            daysOff: bridge.totalDays,
            vacationDays: bridge.vacationDays,
            badge: isNational ? "Nacional" : "Estadual · \(ufCode)",
            isNational: isNational
        )
    }
}
