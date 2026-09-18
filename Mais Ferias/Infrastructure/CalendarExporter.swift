import Foundation
import EventKit

/// Adiciona um período de férias sugerido ao calendário do usuário como evento de dia inteiro.
enum CalendarExporter {
    static func addVacation(named name: String, from start: Date, to end: Date) async -> Bool {
        let store = EKEventStore()
        let granted = (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        guard granted else { return false }

        let event = EKEvent(eventStore: store)
        event.title = "Férias — \(name)"
        event.isAllDay = true
        event.startDate = start
        event.endDate = end
        event.notes = "Sugestão do Mais Férias: emende o feriado e descanse mais."
        event.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(event, span: .thisEvent)
            return true
        } catch {
            return false
        }
    }
}
