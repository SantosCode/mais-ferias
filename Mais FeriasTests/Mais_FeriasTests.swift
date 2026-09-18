//
//  Mais_FeriasTests.swift
//  Mais FeriasTests
//
//  Created by Luis Santos on 15/09/26.
//

import Testing
import Foundation
import SwiftData
@testable import Mais_Ferias

private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar(identifier: .gregorian).date(from: components)!
}

private let testCalendar = Calendar(identifier: .gregorian)

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

// MARK: - Emenda pluralization

@Suite("Emenda labels")
struct EmendaLabelTests {

    @Test("daysOff pluralization")
    func daysOffPluralization() {
        let single = Emenda(date: .now, month: "JAN", day: "01", name: "X", weekday: "Segunda-feira", range: "01 Jan", daysOff: 1, vacationDays: 0, badge: "Nacional", isNational: true)
        let plural = Emenda(date: .now, month: "JAN", day: "01", name: "X", weekday: "Segunda-feira", range: "01 Jan", daysOff: 6, vacationDays: 3, badge: "Nacional", isNational: true)
        #expect(single.daysOffUnitLabel == "dia")
        #expect(single.daysOffLabel == "1 dia")
        #expect(plural.daysOffUnitLabel == "dias")
        #expect(plural.daysOffLabel == "6 dias")
    }

    @Test("daysGained is daysOff minus vacationDays, with matching pluralization")
    func daysGainedComputation() {
        let emenda = Emenda(date: .now, month: "JAN", day: "01", name: "X", weekday: "Segunda-feira", range: "01 Jan", daysOff: 9, vacationDays: 4, badge: "Nacional", isNational: true)
        #expect(emenda.daysGained == 5)
        #expect(emenda.daysGainedLabel == "5 dias")

        let single = Emenda(date: .now, month: "JAN", day: "01", name: "X", weekday: "Segunda-feira", range: "01 Jan", daysOff: 6, vacationDays: 5, badge: "Nacional", isNational: true)
        #expect(single.daysGained == 1)
        #expect(single.daysGainedLabel == "1 dia")
    }
}

// MARK: - WorkSchedule

@Suite("WorkSchedule")
struct WorkScheduleTests {

    @Test("weekdays schedule treats Saturday and Sunday as free")
    func weekdaysFreeDays() {
        #expect(WorkSchedule.weekdays.freeWeekdays == [1, 7])
    }

    @Test("everyDay schedule has no free days")
    func everyDayFreeDays() {
        #expect(WorkSchedule.everyDay.freeWeekdays.isEmpty)
    }

    @Test("Exposes exactly two schedules with the expected Portuguese labels")
    func allCases() {
        #expect(WorkSchedule.allCases.count == 2)
        #expect(WorkSchedule.weekdays.label == "Segunda a sexta")
        #expect(WorkSchedule.everyDay.label == "Todos os dias")
    }
}

// MARK: - BrazilState

@Suite("BrazilState")
struct BrazilStateTests {

    @Test("Covers all 27 Brazilian states/federal district exactly once")
    func coversAllStates() {
        #expect(BrazilState.allCases.count == 27)
        let names = Set(BrazilState.allCases.map(\.fullName))
        #expect(names.count == 27) // no duplicate full names
    }

    @Test("Every state has a non-empty full name and id matches its raw value")
    func fullNamesAndIdentifiers() {
        for state in BrazilState.allCases {
            #expect(!state.fullName.isEmpty)
            #expect(state.id == state.rawValue)
        }
    }
}

// MARK: - VacationPeriod

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

// MARK: - AppState.twelveMonthWindow

@Suite("AppState.twelveMonthWindow")
struct TwelveMonthWindowTests {

    @Test("Rolls forward exactly one year from the 1st of the current month")
    func rollsForwardOneYear() {
        let (start, end) = AppState.twelveMonthWindow(from: makeDate(2026, 9, 15), calendar: testCalendar)
        #expect(start == makeDate(2026, 9, 1))
        #expect(end == makeDate(2027, 9, 1))
    }

    @Test("Handles a January reference date without needing a 3rd calendar year")
    func januaryEdgeCase() {
        let (start, end) = AppState.twelveMonthWindow(from: makeDate(2026, 1, 15), calendar: testCalendar)
        #expect(start == makeDate(2026, 1, 1))
        #expect(end == makeDate(2027, 1, 1))
    }
}

// MARK: - AppState

@MainActor
private func makeAppState() -> AppState {
    let container = try! ModelContainer(for: UserProfile.self, VacationPeriod.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return AppState(modelContext: container.mainContext)
}

@Suite("AppState defaults and preferences", .serialized)
@MainActor
struct AppStateDefaultsTests {

    @Test("Starts with sensible defaults for a first-time profile")
    func defaults() {
        let appState = makeAppState()
        #expect(appState.selectedUF == .SP)
        #expect(appState.workSchedule == .weekdays)
        #expect(appState.desiredVacationDays == 5)
        #expect(appState.userName == "Luís Santos")
        #expect(appState.initials == "LS")
        #expect(appState.vacations.isEmpty)
        #expect(appState.totalVacationDays == 0)
    }

    @Test("selectedUF, workSchedule, and desiredVacationDays persist through their setters")
    func preferencesPersist() {
        let appState = makeAppState()
        appState.selectedUF = .RJ
        appState.workSchedule = .everyDay
        appState.desiredVacationDays = 12
        #expect(appState.selectedUF == .RJ)
        #expect(appState.workSchedule == .everyDay)
        #expect(appState.desiredVacationDays == 12)
    }
}

@Suite("AppState vacation periods", .serialized)
@MainActor
struct AppStateVacationTests {

    @Test("Adding vacations updates the list and the total day count")
    func addVacationUpdatesTotals() {
        let appState = makeAppState()
        appState.addVacation(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13))
        appState.addVacation(start: makeDate(2026, 6, 1), end: makeDate(2026, 6, 1))
        #expect(appState.vacations.count == 2)
        #expect(appState.totalVacationDays == 5) // 4 + 1
    }

    @Test("Vacations are sorted by start date regardless of insertion order")
    func vacationsSortedByStart() {
        let appState = makeAppState()
        appState.addVacation(start: makeDate(2026, 6, 1), end: makeDate(2026, 6, 1))
        appState.addVacation(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13))
        #expect(appState.vacations.map(\.start) == [makeDate(2026, 3, 10), makeDate(2026, 6, 1)])
    }

    @Test("Removing a vacation drops it from the list and totals")
    func removeVacation() {
        let appState = makeAppState()
        appState.addVacation(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13))
        let toRemove = appState.vacations[0]
        appState.removeVacation(toRemove)
        #expect(appState.vacations.isEmpty)
        #expect(appState.totalVacationDays == 0)
    }
}

@Suite("AppState.daysGained", .serialized)
@MainActor
struct AppStateDaysGainedTests {

    @Test("A period immediately adjacent to a fallback holiday's weekend gains the expected bonus days")
    func gainsBonusDaysNextToHoliday() {
        let appState = makeAppState()
        // Matches AppState.fallbackEmendas' "Revolução Constitucionalista" (Thu, Jul 9 2026):
        // registering exactly its 3 vacation days should reproduce its 3-day gain.
        let period = VacationPeriod(start: makeDate(2026, 7, 6), end: makeDate(2026, 7, 8))
        #expect(appState.daysGained(for: period) == 3)
    }

    @Test("A period with no adjacent weekend or holiday gains nothing")
    func gainsNothingMidweek() {
        let appState = makeAppState()
        let period = VacationPeriod(start: makeDate(2026, 2, 4), end: makeDate(2026, 2, 5)) // Wed–Thu, far from any fallback holiday
        #expect(appState.daysGained(for: period) == 0)
    }
}
