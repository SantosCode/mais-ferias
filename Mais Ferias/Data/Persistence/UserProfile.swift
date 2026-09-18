import Foundation
import SwiftData

/// O perfil único do usuário no aparelho — estado (UF), jornada e períodos de férias
/// registrados, persistidos localmente via SwiftData para sobreviver a relançamentos.
@Model
final class UserProfile {
    var name: String
    var selectedUFRaw: String
    var workScheduleRaw: String = WorkSchedule.weekdays.rawValue
    var appearanceRaw: String = Appearance.automatic.rawValue
    var desiredVacationDays: Int = 5
    var annualVacationAllowance: Int = 30
    var notificationsEnabled: Bool = false
    var hasOnboarded: Bool = false
    @Relationship(deleteRule: .cascade) var vacations: [VacationPeriod] = []

    init(name: String, selectedUFRaw: String) {
        self.name = name
        self.selectedUFRaw = selectedUFRaw
    }
}
