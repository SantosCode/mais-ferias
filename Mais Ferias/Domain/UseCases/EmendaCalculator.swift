import Foundation

/// Calcula "emendas" — os dias de folga ganhos ao ligar um feriado aos dias livres
/// mais próximos (fins de semana, conforme a jornada) com um período contíguo de férias.
enum EmendaCalculator {
    struct Bridge {
        /// Primeiro e último dia pago de férias. Quando `vacationDays` é 0 não há
        /// nada a solicitar e ambos colapsam para o próprio feriado.
        let vacationStart: Date
        let vacationEnd: Date
        /// A folga contígua completa: os dias de férias mais o feriado e todos os
        /// dias livres adjacentes dos dois lados.
        let fullStart: Date
        let fullEnd: Date
        let vacationDays: Int
        let totalDays: Int
    }

    /// Sugere o período de férias que emenda `holiday` a um bloco livre vizinho,
    /// respeitando o art. 134 §3º da CLT (Lei nº 13.467/2017): as férias não podem
    /// começar nos dois dias que antecedem o descanso semanal remunerado (ou seja,
    /// nunca na sexta ou no sábado quando o domingo é livre) nem nos dois dias que
    /// antecedem um feriado.
    ///
    /// A ponte base preenche o menor intervalo legal de dias úteis entre o feriado
    /// e um bloco livre. Um orçamento `maxVacationDays` acima desse mínimo estende
    /// as férias para frente, contando fins de semana absorvidos como dias pagos
    /// (férias correm em dias corridos); um orçamento igual ou abaixo do mínimo
    /// mantém a ponte base — o mínimo legal é sempre sugerido.
    static func bridge(for holiday: Date, calendar: Calendar, schedule: WorkSchedule = .weekdays, maxVacationDays: Int = 0) -> Bridge {
        let freeWeekdays = schedule.freeWeekdays

        func day(_ offset: Int, from date: Date) -> Date {
            calendar.date(byAdding: .day, value: offset, to: date)!
        }
        func isWeekendFree(_ date: Date) -> Bool {
            freeWeekdays.contains(calendar.component(.weekday, from: date))
        }
        func isFree(_ date: Date) -> Bool {
            isWeekendFree(date) || calendar.isDate(date, inSameDayAs: holiday)
        }
        func distanceToWeekendFree(from date: Date, direction: Int) -> Int? {
            guard !freeWeekdays.isEmpty else { return nil }
            for step in 1...7 where isWeekendFree(day(direction * step, from: date)) {
                return step
            }
            return nil
        }

        // CLT art. 134 §3º: férias não iniciam na sexta/sábado (os dois dias antes
        // do descanso de domingo) nem nos dois dias imediatamente antes do feriado.
        func isLegalStart(_ start: Date) -> Bool {
            if freeWeekdays.contains(1) {
                let weekday = calendar.component(.weekday, from: start)
                if weekday == 6 || weekday == 7 { return false }
            }
            let daysToHoliday = calendar.dateComponents([.day], from: start, to: holiday).day ?? 0
            return daysToHoliday != 1 && daysToHoliday != 2
        }

        // Ponte base: o menor intervalo legal entre o feriado e um bloco livre,
        // olhando para trás e para frente. Intervalo 0 de um lado significa que o
        // feriado já encosta naquele bloco livre — nada a emendar ali.
        // Feriado que já cai em dia livre não precisa de férias.
        var vacationStart = holiday
        var vacationEnd = holiday
        var vacationDays = 0
        if !isWeekendFree(holiday),
           let backDist = distanceToWeekendFree(from: holiday, direction: -1),
           let forwardDist = distanceToWeekendFree(from: holiday, direction: 1) {
            var candidates: [(start: Date, end: Date, days: Int)] = []
            let backGap = backDist - 1
            if backGap > 0, isLegalStart(day(-backGap, from: holiday)) {
                candidates.append((day(-backGap, from: holiday), day(-1, from: holiday), backGap))
            }
            let forwardGap = forwardDist - 1
            if forwardGap > 0, isLegalStart(day(1, from: holiday)) {
                candidates.append((day(1, from: holiday), day(forwardGap, from: holiday), forwardGap))
            }
            if let best = candidates.min(by: { $0.days < $1.days }) {
                (vacationStart, vacationEnd, vacationDays) = best
            }
        }

        // Gasta o orçamento acima do mínimo estendendo as férias para frente — só
        // para frente, pois a ponte para trás termina logo antes do feriado e
        // crescê-la dividiria o período. Dias livres no final são aparados: eles
        // estenderiam a folga de graça, então pagá-los não rende nada.
        if maxVacationDays > vacationDays, vacationEnd >= holiday, !isWeekendFree(holiday) {
            var end = vacationEnd
            var appended = 0
            while vacationDays + appended < maxVacationDays {
                end = day(1, from: end)
                appended += 1
            }
            while appended > 0, isWeekendFree(end) {
                end = day(-1, from: end)
                appended -= 1
            }
            if appended > 0 {
                if vacationDays == 0 { vacationStart = day(1, from: holiday) }
                vacationEnd = end
                vacationDays += appended
            }
        }

        // Caminha para fora por todos os dias livres adjacentes para medir a folga completa.
        var fullStart = min(vacationStart, holiday)
        while isFree(day(-1, from: fullStart)) { fullStart = day(-1, from: fullStart) }
        var fullEnd = max(vacationEnd, holiday)
        while isFree(day(1, from: fullEnd)) { fullEnd = day(1, from: fullEnd) }

        let totalDays = (calendar.dateComponents([.day], from: fullStart, to: fullEnd).day ?? 0) + 1
        return Bridge(vacationStart: vacationStart, vacationEnd: vacationEnd, fullStart: fullStart, fullEnd: fullEnd, vacationDays: vacationDays, totalDays: totalDays)
    }

    /// Monta uma `Emenda` para o feriado dado, ou `nil` se o feriado já cai em um
    /// dia livre da jornada (nada a emendar).
    static func makeEmenda(name: String, date: Date, isNational: Bool, ufCode: String, calendar: Calendar, schedule: WorkSchedule = .weekdays, maxVacationDays: Int = 0) -> Emenda? {
        guard !schedule.freeWeekdays.contains(calendar.component(.weekday, from: date)) else { return nil }

        let bridge = EmendaCalculator.bridge(for: date, calendar: calendar, schedule: schedule, maxVacationDays: maxVacationDays)

        let monthFmt = DateFormatter()
        monthFmt.locale = Locale(identifier: "pt_BR")
        monthFmt.dateFormat = "MMM"
        // O pt_BR abrevia meses com ponto final ("jan.") — removê-lo.
        func month(_ date: Date) -> String {
            monthFmt.string(from: date).replacingOccurrences(of: ".", with: "")
        }

        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "dd"

        let weekdayFmt = DateFormatter()
        weekdayFmt.locale = Locale(identifier: "pt_BR")
        weekdayFmt.dateFormat = "EEEE"

        let range: String
        if calendar.isDate(bridge.fullStart, equalTo: bridge.fullEnd, toGranularity: .month) {
            range = "\(dayFmt.string(from: bridge.fullStart))–\(dayFmt.string(from: bridge.fullEnd)) \(month(bridge.fullEnd).capitalized)"
        } else {
            range = "\(dayFmt.string(from: bridge.fullStart)) \(month(bridge.fullStart).capitalized) – \(dayFmt.string(from: bridge.fullEnd)) \(month(bridge.fullEnd).capitalized)"
        }

        return Emenda(
            date: date,
            month: month(date).uppercased(),
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
