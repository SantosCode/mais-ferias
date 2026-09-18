import Foundation
import SwiftData

/// Um período de férias registrado pelo usuário, persistido localmente via SwiftData.
@Model
final class VacationPeriod: Identifiable {
    var id: UUID = UUID()
    var start: Date
    var end: Date

    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    var days: Int {
        (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    var rangeLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd MMM"
        // O pt_BR abrevia meses com ponto final ("mar.") — removê-lo.
        func label(_ date: Date) -> String {
            f.string(from: date).replacingOccurrences(of: ".", with: "").capitalized
        }
        return "\(label(start)) – \(label(end))"
    }
}
