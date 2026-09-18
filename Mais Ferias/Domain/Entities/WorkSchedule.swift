import Foundation

/// Em quais dias da semana o usuário trabalha — determina quais dias já são livres
/// (e, portanto, quantos dias de férias uma emenda realmente custa).
enum WorkSchedule: String, CaseIterable, Identifiable {
    case weekdays
    case everyDay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekdays: return "Segunda a sexta"
        case .everyDay: return "Todos os dias"
        }
    }

    /// Valores de dia da semana do Foundation (dom=1...sáb=7) que já são livres — sem gastar férias.
    var freeWeekdays: Set<Int> {
        switch self {
        case .weekdays: return [1, 7]
        case .everyDay: return []
        }
    }
}
