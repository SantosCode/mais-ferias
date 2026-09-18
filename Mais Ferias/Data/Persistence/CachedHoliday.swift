import Foundation
import SwiftData

/// Um feriado persistido da última busca bem-sucedida na API, chaveado por estado —
/// permite ao app funcionar offline com dados reais em vez de exemplos estáticos.
@Model
final class CachedHoliday {
    var date: Date
    var name: String
    var isNational: Bool
    var ufRaw: String

    init(date: Date, name: String, isNational: Bool, ufRaw: String) {
        self.date = date
        self.name = name
        self.isNational = isNational
        self.ufRaw = ufRaw
    }

    var asHolidayItem: HolidayItem {
        HolidayItem(date: date, name: name, isNational: isNational)
    }
}
