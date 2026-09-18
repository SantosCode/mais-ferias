import Foundation
import UserNotifications

/// Agenda lembretes locais para as próximas emendas, para o usuário não perder a
/// janela de solicitá-las. Apenas notificações locais — sem push/infra remota.
enum NotificationScheduler {
    /// Quantos dias antes do feriado lembrar o usuário de solicitar a emenda.
    private static let leadDays = 21
    /// O UNUserNotificationCenter descarta silenciosamente pedidos além de 64 pendentes — ficar bem abaixo.
    private static let maxScheduled = 20

    /// Pede permissão de notificação se ainda não determinada. Retorna se as
    /// notificações estão autorizadas (já concedidas ou concedidas agora).
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Substitui todos os lembretes pendentes por novos para a lista dada — um por
    /// feriado futuro, `leadDays` antes dele (ou o quanto antes, se esse prazo já
    /// passou mas o feriado ainda está à frente).
    static func scheduleReminders(for emendas: [Emenda], calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let upcoming = emendas.filter { $0.date > now }.sorted { $0.date < $1.date }.prefix(maxScheduled)

        var overdueCount = 0
        for emenda in upcoming {
            guard let idealTrigger = calendar.date(byAdding: .day, value: -leadDays, to: emenda.date) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Hora de planejar sua emenda"
            content.body = "\(emenda.name) (\(emenda.range)): use \(emenda.vacationDays) dia(s) de férias e ganhe \(emenda.daysGainedLabel)."
            content.sound = .default

            // Dispara às 9h do dia ideal; se esse horário já passou, o gatilho de
            // calendário nunca dispararia — usa um intervalo curto, escalonado para
            // não empilhar vários avisos no mesmo segundo.
            var components = calendar.dateComponents([.year, .month, .day], from: idealTrigger)
            components.hour = 9
            let trigger: UNNotificationTrigger
            if let fireDate = calendar.date(from: components), fireDate > now {
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            } else {
                overdueCount += 1
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(60 * overdueCount), repeats: false)
            }

            let request = UNNotificationRequest(identifier: "emenda-\(emenda.id)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
