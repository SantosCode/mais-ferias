import Testing
import Foundation
@testable import Mais_Ferias

// MARK: - VacationPeriod (SwiftData model)

@Suite("VacationPeriod")
struct VacationPeriodTests {

    @Test("A single-day period counts as 1 day")
    func singleDay() {
        let day = makeDate(2026, 3, 10)
        let period = VacationPeriod(start: day, end: day)
        #expect(period.days == 1)
    }

    @Test("Days are counted inclusively of both endpoints")
    func inclusiveRange() {
        let period = VacationPeriod(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13))
        #expect(period.days == 4)
    }

    @Test("rangeLabel formats both endpoints as 'dd MMM'")
    func rangeLabelFormatting() {
        let period = VacationPeriod(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13))
        #expect(period.rangeLabel == "10 Mar – 13 Mar")
    }
}

// MARK: - Ano bissexto

@Suite("Ano bissexto")
struct LeapYearTests {

    @Test("Período atravessando 29 de fevereiro conta o dia extra")
    func vacationAcrossLeapDay() {
        // 2028 é bissexto: 28/02, 29/02 e 01/03 = 3 dias corridos.
        let period = VacationPeriod(start: makeDate(2028, 2, 28), end: makeDate(2028, 3, 1))
        #expect(period.days == 3)
    }

    @Test("Feriado em 29 de fevereiro (terça, 2028) emenda normalmente para frente")
    func bridgeOnLeapDay() {
        let bridge = EmendaCalculator.bridge(for: makeDate(2028, 2, 29), calendar: testCalendar)
        #expect(bridge.vacationStart == makeDate(2028, 3, 1)) // quarta
        #expect(bridge.vacationEnd == makeDate(2028, 3, 3))   // sexta
        #expect(bridge.vacationDays == 3)
        #expect(bridge.totalDays == 6) // 29/02 (ter) até 05/03 (dom)
    }
}
