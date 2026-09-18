import Foundation
import SwiftData
@testable import Mais_Ferias

/// Shared helpers for the whole test target.

let testCalendar = Calendar(identifier: .gregorian)

func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar(identifier: .gregorian).date(from: components)!
}

/// An AppState backed by an in-memory store, isolated per test. Pass a fake
/// repository to exercise the holiday-loading paths without the network.
@MainActor
func makeAppState(repository: (any HolidayRepository)? = nil) -> AppState {
    let container = try! ModelContainer(for: UserProfile.self, VacationPeriod.self, CachedHoliday.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    if let repository {
        return AppState(modelContext: container.mainContext, holidayRepository: repository)
    }
    return AppState(modelContext: container.mainContext)
}
