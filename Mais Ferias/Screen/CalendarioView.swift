import SwiftUI

struct CalendarioView: View {
    @Environment(AppState.self) var appState
    let weekLabels = ["D", "S", "T", "Q", "Q", "S", "S"]

    private var calendar: Calendar { Calendar(identifier: .gregorian) }
    private var year: Int { calendar.component(.year, from: Date()) }

    private struct MonthData {
        let title: String
        let rows: [[(label: String, kind: String)]]
        let emendas: [Emenda]
    }

    private var holidayDates: Set<Date> {
        Set(appState.emendas.map { calendar.startOfDay(for: $0.date) })
    }

    private var vacationDates: Set<Date> {
        var dates = Set<Date>()
        for e in appState.emendas {
            let bridge = EmendaCalculator.bridge(for: e.date, calendar: calendar)
            var d = bridge.start
            while d <= bridge.end {
                dates.insert(calendar.startOfDay(for: d))
                guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
                d = next
            }
        }
        return dates
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    HStack { Text("Calendário").font(.system(size: 28, weight: .bold)).foregroundStyle(.white); Spacer() }

                    HStack(spacing: 14) {
                        legend(color: accentOrange, filled: true, label: "Feriado")
                        legend(color: accentOrange, filled: false, label: "Férias sugeridas")
                        legend(color: .white.opacity(0.2), filled: true, label: "Fim de semana")
                    }

                    ForEach(1...12, id: \.self) { month in
                        monthCard(for: month)
                    }
                }
                .padding(18)
                .padding(.bottom, 20)
            }
        }
    }

    private func monthCard(for month: Int) -> some View {
        let data = monthData(for: month)
        return VStack(spacing: 12) {
            Text(data.title).font(.headline).foregroundStyle(.white)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(weekLabels.indices, id: \.self) { i in
                    Text(weekLabels[i]).font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.5))
                }
                ForEach(Array(data.rows.enumerated()), id: \.offset) { _, row in
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        dayCell(cell.label, kind: cell.kind)
                    }
                }
            }

            ForEach(data.emendas) { e in
                emendaHighlight(e)
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 26)
    }

    private func monthData(for month: Int) -> MonthData {
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return MonthData(title: "", rows: [], emendas: [])
        }

        let holidays = holidayDates
        let vacations = vacationDates

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) // 1 = Sunday
        var cells: [(label: String, kind: String)] = Array(repeating: ("", "empty"), count: firstWeekday - 1)

        for day in 1...range.count {
            let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
            let startOfDay = calendar.startOfDay(for: date)
            let weekday = calendar.component(.weekday, from: date)
            let kind: String
            if holidays.contains(startOfDay) {
                kind = "holiday"
            } else if weekday == 1 || weekday == 7 {
                kind = "weekend"
            } else if vacations.contains(startOfDay) {
                kind = "vacation"
            } else {
                kind = "normal"
            }
            cells.append(("\(day)", kind))
        }
        while cells.count % 7 != 0 { cells.append(("", "empty")) }

        var rows: [[(label: String, kind: String)]] = []
        var index = 0
        while index < cells.count {
            rows.append(Array(cells[index..<(index + 7)]))
            index += 7
        }

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "pt_BR")
        monthFormatter.dateFormat = "MMMM"
        let title = "\(monthFormatter.string(from: firstOfMonth).capitalized) \(year)"

        let monthEmendas = appState.emendas.filter {
            calendar.component(.month, from: $0.date) == month && calendar.component(.year, from: $0.date) == year
        }

        return MonthData(title: title, rows: rows, emendas: monthEmendas)
    }

    private func emendaHighlight(_ e: Emenda) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(e.range): emende \(e.name)").font(.subheadline.weight(.bold)).foregroundStyle(.white)
                Text("Use \(e.vacationDays) dia(s) de férias e ganhe \(e.daysOff) dias seguidos").font(.caption).foregroundStyle(.white.opacity(0.78))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white)
                .frame(width: 32, height: 32).background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .glassCard(cornerRadius: 22)
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(accentOrange.opacity(0.4)))
    }

    func dayCell(_ label: String, kind: String) -> some View {
        Group {
            switch kind {
            case "empty":
                Color.clear
            case "holiday":
                Text(label).font(.subheadline.weight(.heavy)).foregroundStyle(Color(red: 0.1, green: 0.06, blue: 0.03))
                    .frame(height: 34).frame(maxWidth: .infinity).background(accentOrange, in: RoundedRectangle(cornerRadius: 9))
            case "vacation":
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    .frame(height: 34).frame(maxWidth: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(accentOrange, lineWidth: 1.5))
            case "weekend":
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
                    .frame(height: 34).frame(maxWidth: .infinity).background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            default:
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
                    .frame(height: 34).frame(maxWidth: .infinity)
            }
        }
    }

    func legend(color: Color, filled: Bool, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(filled ? color : .clear)
                .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(color, lineWidth: filled ? 0 : 1.5))
                .frame(width: 9, height: 9)
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.78))
        }
    }
}
