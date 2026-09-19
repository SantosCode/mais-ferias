import SwiftUI
import SwiftData

/// Store observável ao qual a camada Presentation se liga: expõe o perfil
/// persistido, as emendas computadas e as ações disparadas pelas telas. Conversa
/// com a camada Domain (EmendaCalculator, HolidayRepository) e nunca com a API
/// diretamente.
@Observable
final class AppState {
    private let modelContext: ModelContext
    /// Um ModelContext não retém seu container; se o container for desalocado, o
    /// contexto é resetado e `profile` fica inutilizável. Retido explicitamente
    /// para este estado nunca sobreviver ao seu armazenamento.
    private let modelContainer: ModelContainer
    private let holidayRepository: any HolidayRepository
    private var profile: UserProfile

    var emendas: [Emenda] = AppState.fallbackEmendas
    var isLoadingEmendas = false
    var loadErrorMessage: String?

    /// Qual aba a `TabView` do `ContentView` mostra — permite a outras views (ex.:
    /// "Ver todas" na Home) pedir a troca sem serem donas da TabView.
    var selectedTab = 0

    init(modelContext: ModelContext, holidayRepository: any HolidayRepository = FeriadosAPIHolidayRepository()) {
        self.modelContext = modelContext
        self.modelContainer = modelContext.container
        self.holidayRepository = holidayRepository
        if let existing = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first {
            profile = existing
        } else {
            let created = UserProfile(name: "Luís Santos", selectedUFRaw: BrazilState.SP.rawValue)
            modelContext.insert(created)
            profile = created
            try? modelContext.save()
        }
    }

    var userName: String {
        get { profile.name }
        set {
            guard profile.name != newValue else { return }
            profile.name = newValue
            save()
        }
    }

    var initials: String {
        let letters = userName.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var selectedUF: BrazilState {
        get { BrazilState(rawValue: profile.selectedUFRaw) ?? .SP }
        set {
            guard selectedUF != newValue else { return }
            profile.selectedUFRaw = newValue.rawValue
            save()
            Task { await loadEmendas() }
        }
    }

    var workSchedule: WorkSchedule {
        get { WorkSchedule(rawValue: profile.workScheduleRaw) ?? .weekdays }
        set {
            guard workSchedule != newValue else { return }
            profile.workScheduleRaw = newValue.rawValue
            save()
            recomputeEmendas()
        }
    }

    var appearance: Appearance {
        get { Appearance(rawValue: profile.appearanceRaw) ?? .automatic }
        set {
            guard appearance != newValue else { return }
            profile.appearanceRaw = newValue.rawValue
            save()
        }
    }

    /// Quantos dias de férias o usuário topa gastar emendando um único feriado.
    /// As emendas usam no mínimo o mínimo legal, mas crescem até esse valor
    /// (absorvendo fins de semana no caminho) quando ele é maior.
    var desiredVacationDays: Int {
        get { profile.desiredVacationDays }
        set {
            guard profile.desiredVacationDays != newValue else { return }
            profile.desiredVacationDays = newValue
            save()
            recomputeEmendas()
        }
    }

    /// Total de dias de férias a que o usuário tem direito por ano (padrão CLT: 30).
    var annualVacationAllowance: Int {
        get { profile.annualVacationAllowance }
        set {
            guard profile.annualVacationAllowance != newValue else { return }
            profile.annualVacationAllowance = newValue
            save()
        }
    }

    /// Dias ainda disponíveis após subtrair todos os períodos registrados.
    var remainingVacationDays: Int { max(0, annualVacationAllowance - totalVacationDays) }

    /// O conjunto mais eficiente de emendas que cabe no saldo restante,
    /// ignorando feriados passados e os já cobertos por períodos registrados.
    var yearPlan: VacationPlanner.Plan {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let available = emendas.filter { emenda in
            let day = calendar.startOfDay(for: emenda.date)
            guard day >= today else { return false }
            return !vacations.contains { vacation in
                day >= calendar.startOfDay(for: vacation.start) && day <= calendar.startOfDay(for: vacation.end)
            }
        }
        return VacationPlanner.bestPlan(emendas: available, budget: remainingVacationDays)
    }

    /// Se o fluxo de onboarding do primeiro launch foi concluído.
    var hasOnboarded: Bool {
        get { profile.hasOnboarded }
        set {
            guard profile.hasOnboarded != newValue else { return }
            profile.hasOnboarded = newValue
            save()
        }
    }

    /// Se há lembretes locais agendados para as próximas emendas. Definir como
    /// `true` pede permissão de notificação; se negada, a preferência volta a
    /// `false` para a UI nunca dizer "ligado" sem notificar de verdade.
    var notificationsEnabled: Bool {
        get { profile.notificationsEnabled }
        set {
            guard profile.notificationsEnabled != newValue else { return }
            if newValue {
                Task {
                    let granted = await NotificationScheduler.requestAuthorizationIfNeeded()
                    profile.notificationsEnabled = granted
                    save()
                    if granted { await NotificationScheduler.scheduleReminders(for: emendas) }
                }
            } else {
                profile.notificationsEnabled = false
                save()
                NotificationScheduler.cancelAll()
            }
        }
    }

    var vacations: [VacationPeriod] {
        profile.vacations.sorted { $0.start < $1.start }
    }

    var totalVacationDays: Int { vacations.reduce(0) { $0 + $1.days } }

    /// O próximo período de férias registrado ainda não concluído — em andamento
    /// ou futuro (a lista já vem ordenada por início).
    var nextScheduledVacation: VacationPeriod? {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        return vacations.first { calendar.startOfDay(for: $0.end) >= today }
    }

    /// Dias de férias dos períodos registrados que caem no ano-calendário atual —
    /// períodos que cruzam a virada do ano contam só os dias de dentro.
    var vacationDaysUsedThisYear: Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: Date())
        guard let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let yearEnd = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else { return totalVacationDays }
        return vacations.reduce(0) { total, vacation in
            let start = max(calendar.startOfDay(for: vacation.start), yearStart)
            let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: vacation.end)) ?? vacation.end
            let end = min(dayAfterEnd, yearEnd)
            guard end > start else { return total }
            return total + (calendar.dateComponents([.day], from: start, to: end).day ?? 0)
        }
    }

    /// O período de férias que a emenda sugere solicitar (primeiro–último dia pago),
    /// ou `nil` quando ela não precisa de dias de férias.
    func suggestedVacationPeriod(for emenda: Emenda) -> (start: Date, end: Date)? {
        let calendar = Calendar(identifier: .gregorian)
        let bridge = EmendaCalculator.bridge(for: emenda.date, calendar: calendar, schedule: workSchedule, maxVacationDays: desiredVacationDays)
        guard bridge.vacationDays > 0 else { return nil }
        return (bridge.vacationStart, bridge.vacationEnd)
    }

    /// Se o intervalo (em granularidade de dia) toca algum período já registrado —
    /// mesma data ou datas cruzadas.
    func overlapsExistingVacation(start: Date, end: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let newStart = calendar.startOfDay(for: min(start, end))
        let newEnd = calendar.startOfDay(for: max(start, end))
        return vacations.contains { vacation in
            newStart <= calendar.startOfDay(for: vacation.end) && newEnd >= calendar.startOfDay(for: vacation.start)
        }
    }

    /// Registra o período; recusa (retornando `false`) intervalos inválidos ou que
    /// cruzem períodos existentes.
    @discardableResult
    func addVacation(start: Date, end: Date) -> Bool {
        guard end >= start, !overlapsExistingVacation(start: start, end: end) else { return false }
        profile.vacations.append(VacationPeriod(start: start, end: end))
        save()
        return true
    }

    func removeVacation(_ vacation: VacationPeriod) {
        profile.vacations.removeAll { $0.id == vacation.id }
        modelContext.delete(vacation)
        save()
    }

    private func save() {
        try? modelContext.save()
    }

    /// Feriados da busca mais recente bem-sucedida, mantidos para que mudar a jornada
    /// recompute as emendas localmente sem bater na rede de novo.
    private var lastFetchedHolidays: [HolidayItem] = []

    /// Busca os feriados de `selectedUF` cobrindo a janela rolante de 12 meses a
    /// partir do mês atual (ex.: Setembro/2026 – Agosto/2027), que pode cruzar dois
    /// anos-calendário, e recomputa as emendas. Cai para cache/cálculo local (e por
    /// último `fallbackEmendas`) se a requisição falhar (offline, chave inválida).
    @MainActor
    func loadEmendas() async {
        isLoadingEmendas = true
        loadErrorMessage = nil
        let calendar = Calendar(identifier: .gregorian)
        let (windowStart, windowEnd) = AppState.twelveMonthWindow(from: Date(), calendar: calendar)
        let startYear = calendar.component(.year, from: windowStart)
        let endYear = calendar.component(.year, from: windowEnd)
        do {
            var holidays = try await holidayRepository.fetchHolidays(uf: selectedUF, year: startYear)
            if endYear != startYear {
                holidays += try await holidayRepository.fetchHolidays(uf: selectedUF, year: endYear)
            }
            lastFetchedHolidays = holidays.filter { $0.date >= windowStart && $0.date < windowEnd }
            replaceHolidayCache(with: lastFetchedHolidays, uf: selectedUF)
            recomputeEmendas()
        } catch HolidayRepositoryError.unauthorized {
            applyOfflineHolidays(
                windowStart: windowStart, windowEnd: windowEnd, calendar: calendar,
                message: "Chave da Feriados API inválida ou sem permissão."
            )
        } catch {
            applyOfflineHolidays(
                windowStart: windowStart, windowEnd: windowEnd, calendar: calendar,
                message: "Não foi possível carregar os feriados agora."
            )
        }
        isLoadingEmendas = false
    }

    /// Caminho offline: prefere o cache da UF atual; senão, cai para os feriados
    /// nacionais calculados localmente (sem estaduais).
    private func applyOfflineHolidays(windowStart: Date, windowEnd: Date, calendar: Calendar, message: String) {
        let cached = cachedHolidays(for: selectedUF).filter { $0.date >= windowStart && $0.date < windowEnd }
        if !cached.isEmpty {
            loadErrorMessage = "\(message) Mostrando feriados salvos da última atualização."
            lastFetchedHolidays = cached
            recomputeEmendas()
            return
        }
        let startYear = calendar.component(.year, from: windowStart)
        let endYear = calendar.component(.year, from: windowEnd)
        let local = (startYear...endYear)
            .flatMap { LocalHolidayCalculator.nationalHolidays(year: $0, calendar: calendar) }
            .filter { $0.date >= windowStart && $0.date < windowEnd }
        if !local.isEmpty {
            loadErrorMessage = "\(message) Mostrando apenas feriados nacionais (offline)."
            lastFetchedHolidays = local
            recomputeEmendas()
        } else {
            loadErrorMessage = "\(message) Mostrando dados de exemplo."
            lastFetchedHolidays = []
            emendas = AppState.fallbackEmendas
        }
    }

    private func cachedHolidays(for uf: BrazilState) -> [HolidayItem] {
        let raw = uf.rawValue
        let descriptor = FetchDescriptor<CachedHoliday>(predicate: #Predicate { $0.ufRaw == raw })
        let cached = (try? modelContext.fetch(descriptor)) ?? []
        return cached.map(\.asHolidayItem).sorted { $0.date < $1.date }
    }

    private func replaceHolidayCache(with holidays: [HolidayItem], uf: BrazilState) {
        let raw = uf.rawValue
        try? modelContext.delete(model: CachedHoliday.self, where: #Predicate { $0.ufRaw == raw })
        for holiday in holidays {
            modelContext.insert(CachedHoliday(date: holiday.date, name: holiday.name, isNational: holiday.isNational, ufRaw: raw))
        }
        save()
    }

    /// A janela rolante de 12 meses do dia 1º do mês de `date` (inclusivo) até o
    /// dia 1º do mesmo mês no ano seguinte (exclusivo).
    static func twelveMonthWindow(from date: Date, calendar: Calendar) -> (start: Date, end: Date) {
        let components = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: components) ?? date
        let end = calendar.date(byAdding: .month, value: 12, to: start) ?? start
        return (start, end)
    }

    /// Recomputa `emendas` a partir dos últimos feriados buscados usando a UF,
    /// jornada e orçamento de dias atuais.
    private func recomputeEmendas() {
        guard !lastFetchedHolidays.isEmpty else { return }
        let calendar = Calendar(identifier: .gregorian)
        let computed: [Emenda] = lastFetchedHolidays.compactMap { holiday in
            EmendaCalculator.makeEmenda(name: holiday.name, date: holiday.date, isNational: holiday.isNational, ufCode: selectedUF.rawValue, calendar: calendar, schedule: workSchedule, maxVacationDays: desiredVacationDays)
        }
        emendas = computed.sorted { $0.date < $1.date }
        if notificationsEnabled {
            let emendas = self.emendas
            Task { await NotificationScheduler.scheduleReminders(for: emendas) }
        }
    }

    /// Todas as datas de feriado conhecidas — usadas para estender um período
    /// registrado pelos dias livres adjacentes ao calcular os dias de bônus.
    private var holidayDates: Set<Date> {
        let calendar = Calendar(identifier: .gregorian)
        let source = lastFetchedHolidays.isEmpty ? emendas.map { $0.date } : lastFetchedHolidays.map { $0.date }
        return Set(source.map { calendar.startOfDay(for: $0) })
    }

    /// Dias seguidos extras que um período registrado rende além do próprio
    /// tamanho, estendendo-o por fins de semana (conforme a jornada) ou feriados
    /// imediatamente adjacentes.
    func daysGained(for period: VacationPeriod) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        var holidays = holidayDates
        // Períodos fora da janela de 12 meses buscada ainda contam feriados
        // nacionais, via cálculo local.
        let startYear = calendar.component(.year, from: period.start)
        let endYear = calendar.component(.year, from: period.end)
        for year in startYear...(endYear + 1) {
            for holiday in LocalHolidayCalculator.nationalHolidays(year: year, calendar: calendar) {
                holidays.insert(calendar.startOfDay(for: holiday.date))
            }
        }
        let freeWeekdays = workSchedule.freeWeekdays

        func isFree(_ date: Date) -> Bool {
            freeWeekdays.contains(calendar.component(.weekday, from: date)) || holidays.contains(calendar.startOfDay(for: date))
        }

        var start = calendar.startOfDay(for: period.start)
        while let prev = calendar.date(byAdding: .day, value: -1, to: start), isFree(prev) {
            start = prev
        }

        var end = calendar.startOfDay(for: period.end)
        while let next = calendar.date(byAdding: .day, value: 1, to: end), isFree(next) {
            end = next
        }

        let totalDaysOff = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        return totalDaysOff - period.days
    }

    /// Dados de exemplo exibidos antes da primeira busca bem-sucedida, ou se tudo falhar.
    static let fallbackEmendas: [Emenda] = {
        let calendar = Calendar(identifier: .gregorian)
        func date(_ month: Int, _ day: Int, _ year: Int = 2026) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day))!
        }
        return [
            Emenda(date: date(4, 21), month: "ABR", day: "21", name: "Tiradentes", weekday: "Terça-feira", range: "21–26 Abr", daysOff: 6, vacationDays: 3, badge: "Nacional", isNational: true),
            Emenda(date: date(11, 20), month: "NOV", day: "20", name: "Consciência Negra", weekday: "Sexta-feira", range: "14–22 Nov", daysOff: 9, vacationDays: 4, badge: "Nacional", isNational: true),
            Emenda(date: date(1, 1), month: "JAN", day: "01", name: "Ano Novo", weekday: "Quinta-feira", range: "27 Dez – 01 Jan", daysOff: 6, vacationDays: 3, badge: "Nacional", isNational: true),
            Emenda(date: date(7, 9), month: "JUL", day: "09", name: "Revolução Constitucionalista", weekday: "Quinta-feira", range: "04–09 Jul", daysOff: 6, vacationDays: 3, badge: "Estadual · SP", isNational: false),
        ]
    }()
}
