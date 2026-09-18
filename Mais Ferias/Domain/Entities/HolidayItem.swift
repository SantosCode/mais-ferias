import Foundation

/// Um feriado nacional ou estadual dentro da janela de planejamento, independente
/// da fonte de dados que o produziu.
struct HolidayItem: Sendable {
    let date: Date
    let name: String
    let isNational: Bool
}
