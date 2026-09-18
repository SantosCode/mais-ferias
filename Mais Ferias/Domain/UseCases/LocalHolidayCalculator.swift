import Foundation

/// Calcula feriados nacionais brasileiros localmente — o fallback offline quando a
/// API e o cache estão indisponíveis, e a fonte de datas para o cálculo de dias de
/// bônus fora da janela buscada. Feriados estaduais exigem a API.
enum LocalHolidayCalculator {
    /// Domingo de Páscoa gregoriano (algoritmo de Meeus/Jones/Butcher).
    static func easter(year: Int, calendar: Calendar) -> Date? {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    /// Feriados nacionais de data fixa mais a Sexta-feira Santa (móvel). Pontos
    /// facultativos (Carnaval, Corpus Christi) ficam de fora, igual ao comportamento
    /// `facultativos=false` da API.
    static func nationalHolidays(year: Int, calendar: Calendar) -> [HolidayItem] {
        let fixed: [(Int, Int, String)] = [
            (1, 1, "Confraternização Universal"),
            (4, 21, "Tiradentes"),
            (5, 1, "Dia do Trabalho"),
            (9, 7, "Independência do Brasil"),
            (10, 12, "Nossa Senhora Aparecida"),
            (11, 2, "Finados"),
            (11, 15, "Proclamação da República"),
            (11, 20, "Dia da Consciência Negra"),
            (12, 25, "Natal"),
        ]
        var items: [HolidayItem] = fixed.compactMap { month, day, name in
            calendar.date(from: DateComponents(year: year, month: month, day: day)).map {
                HolidayItem(date: $0, name: name, isNational: true)
            }
        }
        if let easter = easter(year: year, calendar: calendar),
           let goodFriday = calendar.date(byAdding: .day, value: -2, to: easter) {
            items.append(HolidayItem(date: goodFriday, name: "Sexta-feira Santa", isNational: true))
        }
        return items.sorted { $0.date < $1.date }
    }
}
