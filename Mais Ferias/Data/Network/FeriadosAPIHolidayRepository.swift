import Foundation

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

/// `HolidayRepository` implementado sobre a Feriados API (https://feriadosapi.com/docs).
struct FeriadosAPIHolidayRepository: HolidayRepository {
    private static let baseURL = "https://feriadosapi.com/api/v1"

    /// Busca todos os feriados de `uf` e `year` — o endpoint estadual já inclui os
    /// nacionais, então uma única chamada paginada cobre os dois.
    func fetchHolidays(uf: BrazilState, year: Int) async throws -> [HolidayItem] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        formatter.dateFormat = "dd/MM/yyyy"

        var items: [HolidayItem] = []
        var page = 1
        var totalPages = 1

        repeat {
            var components = URLComponents(string: "\(Self.baseURL)/feriados/estado/\(uf.rawValue)")!
            components.queryItems = [
                URLQueryItem(name: "ano", value: String(year)),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "facultativos", value: "false"),
            ]

            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(Secrets.feriadosAPIKey)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw HolidayRepositoryError.unauthorized
            }

            let decoded = try JSONDecoder().decode(FeriadosResponse.self, from: data)
            for item in decoded.feriados {
                guard let date = formatter.date(from: item.data) else { throw HolidayRepositoryError.invalidDate }
                items.append(HolidayItem(date: date, name: item.nome, isNational: item.tipo == "NACIONAL"))
            }
            totalPages = decoded.meta.totalPages

            page += 1
        } while page <= totalPages

        return items
    }
}
