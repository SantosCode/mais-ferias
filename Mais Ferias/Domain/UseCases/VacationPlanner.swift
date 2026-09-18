import Foundation

/// Escolhe o melhor conjunto de emendas que cabe no saldo de férias restante do
/// usuário, respeitando o fracionamento do art. 134 §1º da CLT: até 3 períodos,
/// um deles com 14+ dias e os demais com 5+ dias cada.
enum VacationPlanner {
    /// Dias reservados para o período principal de férias (14+ por lei).
    static let mainPeriodDays = 14
    /// Duração mínima legal de cada período fracionado.
    static let minimumFractionDays = 5
    /// Além do principal, a CLT permite no máximo 2 períodos fracionados.
    static let maxFractionedPeriods = 2

    struct Plan {
        let emendas: [Emenda]
        /// Dias cobrados do saldo — cada emenda custa no mínimo 5 dias (mínimo legal
        /// de um período fracionado), mesmo que a ponte precise de menos.
        let vacationDaysUsed: Int
        let totalDaysOff: Int
        /// Dias reservados para as férias principais (0 quando o saldo não comporta).
        let mainPeriodReserve: Int
    }

    /// Custo legal de uma emenda como período fracionado.
    static func chargedDays(for emenda: Emenda) -> Int {
        max(minimumFractionDays, emenda.vacationDays)
    }

    /// Guloso por eficiência (dias de folga por dia cobrado), data mais próxima
    /// primeiro em empates. Reserva 14 dias para o período principal quando o
    /// saldo comporta principal + ao menos uma fração, e limita a 2 emendas.
    static func bestPlan(emendas: [Emenda], budget: Int) -> Plan {
        let budget = max(0, budget)
        let reserve = budget >= mainPeriodDays + minimumFractionDays ? mainPeriodDays : 0
        var remaining = budget - reserve

        let ranked = emendas
            .filter { $0.vacationDays > 0 }
            .sorted { lhs, rhs in
                let lhsRatio = Double(lhs.daysOff) / Double(chargedDays(for: lhs))
                let rhsRatio = Double(rhs.daysOff) / Double(chargedDays(for: rhs))
                return lhsRatio == rhsRatio ? lhs.date < rhs.date : lhsRatio > rhsRatio
            }

        var chosen: [Emenda] = []
        for emenda in ranked where chosen.count < maxFractionedPeriods && chargedDays(for: emenda) <= remaining {
            chosen.append(emenda)
            remaining -= chargedDays(for: emenda)
        }
        chosen.sort { $0.date < $1.date }
        return Plan(
            emendas: chosen,
            vacationDaysUsed: chosen.reduce(0) { $0 + chargedDays(for: $1) },
            totalDaysOff: chosen.reduce(0) { $0 + $1.daysOff },
            mainPeriodReserve: reserve
        )
    }
}
