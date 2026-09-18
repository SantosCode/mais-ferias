import Testing
import Foundation
@testable import Mais_Ferias

// MARK: - EmendaCalculator.bridge — one scenario per weekday

@Suite("EmendaCalculator.bridge — weekday scenarios")
struct EmendaCalculatorBridgeWeekdayTests {

    @Test("Monday holiday bridges the whole following work week")
    func monday() {
        let holiday = makeDate(2026, 1, 5) // Monday
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar)
        #expect(bridge.vacationStart == makeDate(2026, 1, 6)) // Tue
        #expect(bridge.vacationEnd == makeDate(2026, 1, 9))   // Fri
        #expect(bridge.vacationDays == 4)
        #expect(bridge.fullStart == makeDate(2026, 1, 3))     // Sat before
        #expect(bridge.fullEnd == makeDate(2026, 1, 11))      // Sun after
        #expect(bridge.totalDays == 9)
    }

    @Test("Tuesday holiday skips the illegal 1-day backward bridge and uses the forward side")
    func tuesday() {
        let holiday = makeDate(2026, 1, 6) // Tuesday
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar)
        #expect(bridge.vacationStart == makeDate(2026, 1, 7)) // Wed
        #expect(bridge.vacationEnd == makeDate(2026, 1, 9))   // Fri
        #expect(bridge.vacationDays == 3)
        #expect(bridge.fullStart == makeDate(2026, 1, 6))     // the holiday itself
        #expect(bridge.fullEnd == makeDate(2026, 1, 11))      // Sun after
        #expect(bridge.totalDays == 6)
    }

    @Test("Wednesday holiday uses the forward side (backward would start within its own 2-day window)")
    func wednesday() {
        let holiday = makeDate(2026, 1, 7) // Wednesday
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar)
        #expect(bridge.vacationStart == makeDate(2026, 1, 8)) // Thu
        #expect(bridge.vacationEnd == makeDate(2026, 1, 9))   // Fri
        #expect(bridge.vacationDays == 2)
        #expect(bridge.fullStart == makeDate(2026, 1, 7))
        #expect(bridge.fullEnd == makeDate(2026, 1, 11))
        #expect(bridge.totalDays == 5)
    }

    @Test("Thursday holiday skips the illegal 1-day forward bridge (starts on Friday) and uses the backward side")
    func thursday() {
        let holiday = makeDate(2026, 1, 1) // Thursday
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar)
        #expect(bridge.vacationStart == makeDate(2025, 12, 29)) // Mon
        #expect(bridge.vacationEnd == makeDate(2025, 12, 31))   // Wed
        #expect(bridge.vacationDays == 3)
        #expect(bridge.fullStart == makeDate(2025, 12, 27))     // Sat before
        #expect(bridge.fullEnd == holiday)
        #expect(bridge.totalDays == 6)
    }

    @Test("Friday holiday bridges the whole preceding work week")
    func friday() {
        let holiday = makeDate(2026, 1, 2) // Friday
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar)
        #expect(bridge.vacationStart == makeDate(2025, 12, 29)) // Mon
        #expect(bridge.vacationEnd == makeDate(2026, 1, 1))     // Thu
        #expect(bridge.vacationDays == 4)
        #expect(bridge.fullStart == makeDate(2025, 12, 27))     // Sat before
        #expect(bridge.fullEnd == makeDate(2026, 1, 4))         // Sun after
        #expect(bridge.totalDays == 9)
    }

    @Test("Saturday holiday needs no vacation days — it's already free")
    func saturday() {
        let holiday = makeDate(2026, 1, 3) // Saturday
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar)
        #expect(bridge.vacationDays == 0)
        #expect(bridge.vacationStart == holiday)
        #expect(bridge.vacationEnd == holiday)
        #expect(bridge.totalDays == 2) // Sat + Sun
    }

    @Test("Sunday holiday needs no vacation days — it's already free")
    func sunday() {
        let holiday = makeDate(2026, 1, 4) // Sunday
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar)
        #expect(bridge.vacationDays == 0)
        #expect(bridge.totalDays == 2) // Sat + Sun
    }
}

// MARK: - EmendaCalculator.bridge — CLT legality regression guard

@Suite("EmendaCalculator.bridge — CLT art. 134 §3º regression")
struct EmendaCalculatorLegalityTests {

    @Test("vacationStart never falls within the 2-day window before a holiday or before Sunday, across a full year")
    func neverStartsIllegally() {
        var day = makeDate(2026, 1, 1)
        let end = makeDate(2027, 1, 1)
        while day < end {
            let weekday = testCalendar.component(.weekday, from: day)
            if weekday != 1 && weekday != 7 {
                let bridge = EmendaCalculator.bridge(for: day, calendar: testCalendar)
                let startWeekday = testCalendar.component(.weekday, from: bridge.vacationStart)
                #expect(startWeekday != 6 && startWeekday != 7, "vacationStart landed on Fri/Sat for holiday \(day)")

                let daysBeforeHoliday = testCalendar.dateComponents([.day], from: bridge.vacationEnd, to: day).day ?? 0
                if daysBeforeHoliday == 1 {
                    // vacationEnd sits immediately before the holiday — this is a backward
                    // bridge, which is only legal once it's 3+ days long.
                    #expect(bridge.vacationDays >= 3, "backward bridge touching \(day) was shorter than 3 days")
                }
            }
            day = testCalendar.date(byAdding: .day, value: 1, to: day)!
        }
    }
}

// MARK: - EmendaCalculator.bridge — maxVacationDays extension

@Suite("EmendaCalculator.bridge — desired vacation-day budget")
struct EmendaCalculatorExtensionTests {

    @Test("Budget above the minimum pushes vacationEnd forward, absorbing the next weekend as paid days")
    func extendsPastMinimum() {
        let holiday = makeDate(2026, 1, 5) // Monday, base bridge = 4 vacation days / 9 total
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar, maxVacationDays: 7)
        #expect(bridge.vacationDays == 7)
        #expect(bridge.vacationEnd == makeDate(2026, 1, 12)) // Fri + Sat + Sun + Mon
        #expect(bridge.totalDays == 10)                      // only 1 genuinely new day gained
    }

    @Test("Budget at or below the legal minimum leaves the bridge unchanged")
    func noOpWhenBudgetTooLow() {
        let holiday = makeDate(2026, 1, 5) // Monday, minimum is 4
        let unchanged = EmendaCalculator.bridge(for: holiday, calendar: testCalendar, maxVacationDays: 4)
        let smaller = EmendaCalculator.bridge(for: holiday, calendar: testCalendar, maxVacationDays: 2)
        let base = EmendaCalculator.bridge(for: holiday, calendar: testCalendar)
        #expect(unchanged.vacationDays == base.vacationDays)
        #expect(unchanged.vacationEnd == base.vacationEnd)
        #expect(smaller.vacationDays == base.vacationDays)
    }

    @Test("Extending an 'every day' schedule bridge always gains exactly the holiday itself")
    func extendsEveryDaySchedule() {
        let holiday = makeDate(2026, 1, 5)
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar, schedule: .everyDay, maxVacationDays: 5)
        #expect(bridge.vacationDays == 5)
        #expect(bridge.vacationEnd == makeDate(2026, 1, 10))
        #expect(bridge.totalDays == 6) // 5 paid days + the holiday
        #expect(bridge.totalDays - bridge.vacationDays == 1)
    }
}

// MARK: - EmendaCalculator.bridge — "todos os dias" (everyDay) schedule

@Suite("EmendaCalculator.bridge — everyDay schedule")
struct EmendaCalculatorEveryDayTests {

    @Test("With no free weekdays, the holiday itself is the only day off and costs nothing")
    func holidayAloneIsFree() {
        let holiday = makeDate(2026, 1, 6) // any weekday
        let bridge = EmendaCalculator.bridge(for: holiday, calendar: testCalendar, schedule: .everyDay)
        #expect(bridge.vacationDays == 0)
        #expect(bridge.vacationStart == holiday)
        #expect(bridge.vacationEnd == holiday)
        #expect(bridge.totalDays == 1)
    }
}

// MARK: - EmendaCalculator.makeEmenda

@Suite("EmendaCalculator.makeEmenda")
struct MakeEmendaTests {

    @Test("Returns nil for a weekend holiday under a weekdays schedule (no bridge to suggest)")
    func nilOnWeekendForWeekdaysSchedule() {
        let saturday = makeDate(2026, 1, 3)
        let sunday = makeDate(2026, 1, 4)
        #expect(EmendaCalculator.makeEmenda(name: "Teste", date: saturday, isNational: true, ufCode: "SP", calendar: testCalendar) == nil)
        #expect(EmendaCalculator.makeEmenda(name: "Teste", date: sunday, isNational: true, ufCode: "SP", calendar: testCalendar) == nil)
    }

    @Test("Still returns an entry for a weekend holiday under an everyDay schedule")
    func nonNilOnWeekendForEveryDaySchedule() {
        let saturday = makeDate(2026, 1, 3)
        let emenda = EmendaCalculator.makeEmenda(name: "Teste", date: saturday, isNational: true, ufCode: "SP", calendar: testCalendar, schedule: .everyDay)
        #expect(emenda != nil)
        #expect(emenda?.vacationDays == 0)
    }

    @Test("National holidays get the Nacional badge; state holidays get Estadual · UF")
    func badgeFormatting() {
        let holiday = makeDate(2026, 1, 5) // Monday
        let national = EmendaCalculator.makeEmenda(name: "Feriado Nacional", date: holiday, isNational: true, ufCode: "SP", calendar: testCalendar)
        let state = EmendaCalculator.makeEmenda(name: "Feriado Estadual", date: holiday, isNational: false, ufCode: "RJ", calendar: testCalendar)
        #expect(national?.badge == "Nacional")
        #expect(state?.badge == "Estadual · RJ")
    }

    @Test("Formats a same-month range as 'dd–dd MMM'")
    func sameMonthRange() {
        let holiday = makeDate(2026, 1, 5) // full block: 03–11 Jan
        let emenda = EmendaCalculator.makeEmenda(name: "Teste", date: holiday, isNational: true, ufCode: "SP", calendar: testCalendar)
        #expect(emenda?.range == "03–11 Jan")
    }

    @Test("Formats a cross-month range as 'dd MMM – dd MMM'")
    func crossMonthRange() {
        let holiday = makeDate(2026, 1, 1) // full block: 27 Dez – 01 Jan
        let emenda = EmendaCalculator.makeEmenda(name: "Teste", date: holiday, isNational: true, ufCode: "SP", calendar: testCalendar)
        #expect(emenda?.range == "27 Dez – 01 Jan")
    }

    @Test("Carries the holiday name, date, and vacation/day counts through")
    func fieldsMatchBridge() {
        let holiday = makeDate(2026, 1, 6) // Tuesday: 3 vacation days, 6 total
        let emenda = EmendaCalculator.makeEmenda(name: "Feriado X", date: holiday, isNational: true, ufCode: "SP", calendar: testCalendar)
        #expect(emenda?.name == "Feriado X")
        #expect(emenda?.date == holiday)
        #expect(emenda?.vacationDays == 3)
        #expect(emenda?.daysOff == 6)
        #expect(emenda?.weekday.lowercased().contains("terça") == true)
    }
}
