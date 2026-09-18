import Testing
import Foundation
import SwiftData
@testable import Mais_Ferias

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

// MARK: - AppState defaults and preferences

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

// MARK: - AppState vacation periods

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

    @Test("Rejects duplicate and crossing periods, keeping the list unchanged")
    func rejectsOverlappingPeriods() {
        let appState = makeAppState()
        #expect(appState.addVacation(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13)))

        // Mesmo intervalo exato.
        #expect(!appState.addVacation(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13)))
        // Cruzando o início e o fim do período existente.
        #expect(!appState.addVacation(start: makeDate(2026, 3, 8), end: makeDate(2026, 3, 10)))
        #expect(!appState.addVacation(start: makeDate(2026, 3, 13), end: makeDate(2026, 3, 20)))
        // Totalmente contido e totalmente englobando.
        #expect(!appState.addVacation(start: makeDate(2026, 3, 11), end: makeDate(2026, 3, 12)))
        #expect(!appState.addVacation(start: makeDate(2026, 3, 1), end: makeDate(2026, 3, 31)))
        // Fim antes do início também é recusado.
        #expect(!appState.addVacation(start: makeDate(2026, 5, 10), end: makeDate(2026, 5, 1)))

        #expect(appState.vacations.count == 1)
        #expect(appState.overlapsExistingVacation(start: makeDate(2026, 3, 13), end: makeDate(2026, 3, 13)))
    }

    @Test("Adjacent (non-overlapping) periods are still allowed")
    func allowsAdjacentPeriods() {
        let appState = makeAppState()
        #expect(appState.addVacation(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13)))
        #expect(appState.addVacation(start: makeDate(2026, 3, 14), end: makeDate(2026, 3, 16)))
        #expect(appState.vacations.count == 2)
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

// MARK: - Persistência SwiftData

@Suite("Persistência SwiftData", .serialized)
@MainActor
struct SwiftDataPersistenceTests {

    @Test("Perfil, preferências e férias sobrevivem a um relançamento simulado")
    func survivesRelaunch() {
        let container = try! ModelContainer(for: UserProfile.self, VacationPeriod.self, CachedHoliday.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let offline = MockHolidayRepository(behavior: .offline)

        let first = AppState(modelContext: container.mainContext, holidayRepository: offline)
        first.userName = "Ana Souza"
        first.workSchedule = .everyDay
        first.desiredVacationDays = 9
        first.annualVacationAllowance = 20
        first.hasOnboarded = true
        first.addVacation(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13))

        // Um contexto NOVO lê direto do armazenamento: só enxerga os dados se o
        // save() realmente os gravou — é o equivalente a relançar o app.
        let freshContext = ModelContext(container)
        let second = AppState(modelContext: freshContext, holidayRepository: offline)
        #expect(second.userName == "Ana Souza")
        #expect(second.workSchedule == .everyDay)
        #expect(second.desiredVacationDays == 9)
        #expect(second.annualVacationAllowance == 20)
        #expect(second.hasOnboarded)
        #expect(second.vacations.count == 1)
        #expect(second.totalVacationDays == 4)
    }

    @Test("Remoção de férias também é persistida")
    func removalPersists() {
        let container = try! ModelContainer(for: UserProfile.self, VacationPeriod.self, CachedHoliday.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let offline = MockHolidayRepository(behavior: .offline)

        let first = AppState(modelContext: container.mainContext, holidayRepository: offline)
        first.addVacation(start: makeDate(2026, 3, 10), end: makeDate(2026, 3, 13))
        first.removeVacation(first.vacations[0])

        let second = AppState(modelContext: ModelContext(container), holidayRepository: offline)
        #expect(second.vacations.isEmpty)
    }
}

// MARK: - AppState.daysGained

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
