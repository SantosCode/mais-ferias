import Testing
import Foundation
@testable import Mais_Ferias

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
