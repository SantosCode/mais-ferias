import Foundation

enum HolidayRepositoryError: Error {
    case invalidDate
    case unauthorized
}

/// Fonte de feriados brasileiros por estado e ano, na visão do domínio.
/// As implementações concretas vivem na camada Data.
protocol HolidayRepository: Sendable {
    func fetchHolidays(uf: BrazilState, year: Int) async throws -> [HolidayItem]
}
