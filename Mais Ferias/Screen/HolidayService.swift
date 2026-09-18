import Foundation
import Alamofire

private nonisolated struct FeriadosResponse: Decodable, Sendable {
    let feriados: [FeriadoItem]
    let meta: FeriadosMeta
}

private nonisolated struct FeriadoItem: Decodable, Sendable {
    let data: String
    let nome: String
    let tipo: String
}

private nonisolated struct FeriadosMeta: Decodable, Sendable {
    let page: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page
        case totalPages = "total_pages"
    }
}

struct HolidayItem: Sendable {
    let date: Date
    let name: String
    let isNational: Bool
}

enum HolidayServiceError: Error {
    case invalidDate
    case unauthorized
}

/// Fetches Brazilian holidays from Feriados API (https://feriadosapi.com/docs).
enum HolidayService {
    private static let baseURL = "https://feriadosapi.com/api/v1"

    private static var headers: HTTPHeaders {
        [.authorization(bearerToken: Secrets.feriadosAPIKey)]
    }

    /// Fetches every holiday for `uf` and `year` — the state endpoint already includes
    /// national holidays, so a single paginated call covers both.
    static func fetchHolidays(uf: BrazilState, year: Int) async throws -> [HolidayItem] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        formatter.dateFormat = "dd/MM/yyyy"

        var items: [HolidayItem] = []
        var page = 1
        var totalPages = 1

        repeat {
            let request = AF.request(
                "\(baseURL)/feriados/estado/\(uf.rawValue)",
                parameters: ["ano": year, "page": page, "limit": 100, "facultativos": false],
                headers: headers
            )
            .validate()

            do {
                let response = try await request.serializingDecodable(FeriadosResponse.self).value
                for item in response.feriados {
                    guard let date = formatter.date(from: item.data) else { throw HolidayServiceError.invalidDate }
                    items.append(HolidayItem(date: date, name: item.nome, isNational: item.tipo == "NACIONAL"))
                }
                totalPages = response.meta.totalPages
            } catch let error as AFError where error.responseCode == 401 || error.responseCode == 403 {
                throw HolidayServiceError.unauthorized
            }

            page += 1
        } while page <= totalPages

        return items
    }
}
