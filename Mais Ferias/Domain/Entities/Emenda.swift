import Foundation

/// Uma oportunidade de emenda ao redor de um feriado: quantos dias de férias custa,
/// quanto dura a folga resultante e as strings de exibição que a UI precisa.
struct Emenda: Identifiable {
    let id = UUID()
    let date: Date
    let month: String
    let day: String
    let name: String
    let weekday: String
    let range: String
    let daysOff: Int
    let vacationDays: Int
    let badge: String
    let isNational: Bool

    var daysOffUnitLabel: String { daysOff == 1 ? "dia" : "dias" }
    var daysOffLabel: String { "\(daysOff) \(daysOffUnitLabel)" }

    /// Os dias de bônus que a emenda realmente rende — `daysOff` menos os dias de
    /// férias gastos. É o que "você ganha" deve exibir, já que `daysOff` sozinho é
    /// a duração *total* da folga, não o ganho sobre o custo.
    var daysGained: Int { daysOff - vacationDays }
    var daysGainedUnitLabel: String { daysGained == 1 ? "dia" : "dias" }
    var daysGainedLabel: String { "\(daysGained) \(daysGainedUnitLabel)" }
}
