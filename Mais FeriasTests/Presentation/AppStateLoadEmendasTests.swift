import Testing
import Foundation
import SwiftData
@testable import Mais_Ferias

/// Fake repository for exercising loadEmendas without the network.
struct MockHolidayRepository: HolidayRepository {
    enum Behavior: Sendable {
        case success([HolidayItem])
        case unauthorized
        case offline
    }

    let behavior: Behavior

    func fetchHolidays(uf: BrazilState, year: Int) async throws -> [HolidayItem] {
        switch behavior {
        case .success(let items):
            return items.filter { testCalendar.component(.year, from: $0.date) == year }
        case .unauthorized:
            throw HolidayRepositoryError.unauthorized
        case .offline:
            throw URLError(.notConnectedToInternet)
        }
    }
}

@Suite("AppState.loadEmendas", .serialized)
@MainActor
struct AppStateLoadEmendasTests {

    /// A weekday holiday a few months ahead, so it lands inside the rolling window.
    private var futureHoliday: HolidayItem {
        let calendar = testCalendar
        var date = calendar.date(byAdding: .month, value: 2, to: Date())!
        while calendar.component(.weekday, from: date) == 1 || calendar.component(.weekday, from: date) == 7 {
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return HolidayItem(date: calendar.startOfDay(for: date), name: "Feriado Teste", isNational: true)
    }

    @Test("Success computes emendas from the repository and clears the error")
    func successPath() async {
        let appState = makeAppState(repository: MockHolidayRepository(behavior: .success([futureHoliday])))
        await appState.loadEmendas()
        #expect(appState.loadErrorMessage == nil)
        #expect(appState.emendas.count == 1)
        #expect(appState.emendas.first?.name == "Feriado Teste")
    }

    @Test("Unauthorized falls back to locally computed national holidays with a message")
    func unauthorizedPath() async {
        let appState = makeAppState(repository: MockHolidayRepository(behavior: .unauthorized))
        await appState.loadEmendas()
        #expect(appState.loadErrorMessage?.contains("inválida") == true)
        #expect(!appState.emendas.isEmpty)
    }

    @Test("Offline falls back to locally computed national holidays with a message")
    func offlinePath() async {
        let appState = makeAppState(repository: MockHolidayRepository(behavior: .offline))
        await appState.loadEmendas()
        #expect(appState.loadErrorMessage?.contains("offline") == true)
        #expect(!appState.emendas.isEmpty)
    }

    @Test("A successful fetch is cached and reused when a later fetch fails")
    func cacheIsReusedWhenOffline() async {
        let container = try! ModelContainer(for: UserProfile.self, VacationPeriod.self, CachedHoliday.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let holiday = futureHoliday

        let online = AppState(modelContext: container.mainContext, holidayRepository: MockHolidayRepository(behavior: .success([holiday])))
        await online.loadEmendas()
        #expect(online.emendas.first?.name == "Feriado Teste")

        // Same store, now offline: the cached holiday must be used instead of the
        // national-holiday fallback.
        let offline = AppState(modelContext: container.mainContext, holidayRepository: MockHolidayRepository(behavior: .offline))
        await offline.loadEmendas()
        #expect(offline.loadErrorMessage?.contains("salvos") == true)
        #expect(offline.emendas.first?.name == "Feriado Teste")
    }
}

@Suite("VacationPlanner")
struct VacationPlannerTests {

    private func emenda(month: Int, day: Int, cost: Int, daysOff: Int) -> Emenda {
        Emenda(date: makeDate(2026, month, day), month: "X", day: "\(day)", name: "E\(month)-\(day)", weekday: "", range: "", daysOff: daysOff, vacationDays: cost, badge: "Nacional", isNational: true)
    }

    @Test("Reserves 14 days for the main period and charges at least 5 per emenda")
    func reservesMainPeriodAndChargesMinimum() {
        let cheap = emenda(month: 3, day: 3, cost: 3, daysOff: 9)   // cobra 5, razão 1.8
        let strong = emenda(month: 5, day: 5, cost: 6, daysOff: 10) // cobra 6, razão 1.67
        let weak = emenda(month: 7, day: 7, cost: 5, daysOff: 6)    // cobra 5, razão 1.2
        // Saldo 30: reserva 14, sobram 16 → cabem cheap (5) e strong (6); weak não entra (limite de 2).
        let plan = VacationPlanner.bestPlan(emendas: [weak, strong, cheap], budget: 30)
        #expect(plan.mainPeriodReserve == 14)
        #expect(plan.emendas.map(\.name) == [cheap.name, strong.name])
        #expect(plan.vacationDaysUsed == 11)
        #expect(plan.totalDaysOff == 19)
    }

    @Test("Small budgets skip the main-period reserve but keep the 5-day minimum")
    func smallBudgetNoReserve() {
        let e = emenda(month: 3, day: 3, cost: 2, daysOff: 6)
        let tooSmall = VacationPlanner.bestPlan(emendas: [e], budget: 4)
        #expect(tooSmall.emendas.isEmpty) // cobra 5 > saldo 4
        let fits = VacationPlanner.bestPlan(emendas: [e], budget: 5)
        #expect(fits.mainPeriodReserve == 0)
        #expect(fits.emendas.count == 1)
        #expect(fits.vacationDaysUsed == 5)
    }

    @Test("Zero budget yields an empty plan")
    func zeroBudget() {
        let plan = VacationPlanner.bestPlan(emendas: [emenda(month: 3, day: 3, cost: 1, daysOff: 4)], budget: 0)
        #expect(plan.emendas.isEmpty)
        #expect(plan.vacationDaysUsed == 0)
        #expect(plan.mainPeriodReserve == 0)
    }
}

@Suite("LocalHolidayCalculator")
struct LocalHolidayCalculatorTests {

    @Test("2026 national holidays include the fixed dates and Sexta-feira Santa (Apr 3)")
    func year2026() {
        let holidays = LocalHolidayCalculator.nationalHolidays(year: 2026, calendar: testCalendar)
        let hasGoodFriday = holidays.contains { $0.date == makeDate(2026, 4, 3) && $0.name == "Sexta-feira Santa" }
        let hasIndependence = holidays.contains { $0.date == makeDate(2026, 9, 7) }
        let allNational = holidays.allSatisfy(\.isNational)
        #expect(holidays.count == 10)
        #expect(hasGoodFriday)
        #expect(hasIndependence)
        #expect(allNational)
    }

    @Test("Easter lands on known dates")
    func easterDates() {
        #expect(LocalHolidayCalculator.easter(year: 2026, calendar: testCalendar) == makeDate(2026, 4, 5))
        #expect(LocalHolidayCalculator.easter(year: 2027, calendar: testCalendar) == makeDate(2027, 3, 28))
    }
}
