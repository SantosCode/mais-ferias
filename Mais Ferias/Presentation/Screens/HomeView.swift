import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) var appState

    /// A janela de emendas começa no dia 1º do mês atual, então feriados deste mês
    /// que já passaram ficam de fora da Home — só interessam datas futuras.
    var upcoming: [Emenda] {
        let today = Calendar.current.startOfDay(for: Date())
        return appState.emendas.filter { $0.date >= today }
    }

    var next: Emenda? { upcoming.first }
    var others: [Emenda] { Array(upcoming.dropFirst()) }

    var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Bom dia"
        case 12..<18: return "Boa tarde"
        default: return "Boa noite"
        }
    }

    var firstName: String {
        appState.userName.split(separator: " ").first.map(String.init) ?? appState.userName
    }

    var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(greeting), \(firstName)").font(.subheadline).foregroundStyle(.white.opacity(0.78))
                            Text("Suas emendas").font(.system(size: 28, weight: .bold))
                        }
                        Spacer()
                        Circle().fill(.white.opacity(0.16)).frame(width: 44, height: 44)
                            .overlay(Text(appState.initials).font(.headline).foregroundStyle(.white))
                            .overlay(Circle().strokeBorder(.white.opacity(0.25)))
                    }
                    .foregroundStyle(.white)

                    if appState.isLoadingEmendas {
                        statusBanner(icon: nil, message: "Carregando feriados…")
                    } else if let message = appState.loadErrorMessage {
                        statusBanner(icon: "exclamationmark.triangle.fill", message: message)
                    }

                    if next != nil {
                        heroCard
                    }
                    scheduledVacationCard
                    statsRow
                    yearPlanCard

                    HStack {
                        Text("Outras emendas").font(.headline).foregroundStyle(.white)
                        Spacer()
                        Button {
                            appState.selectedTab = 1
                        } label: {
                            Text("Ver todas").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    ForEach(others) { e in EmendaRow(emenda: e) }
                }
                .padding(18)
                .padding(.bottom, 20)
            }
            .refreshable { await appState.loadEmendas() }
        }
    }

    var heroCard: some View {
        let next = next!
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("PRÓXIMA EMENDA").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text(next.badge.uppercased()).font(.caption2.weight(.bold))
                    .foregroundStyle(next.isNational ? Color(red: 0.1, green: 0.06, blue: 0.03) : .white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(next.isNational ? accentOrange.opacity(0.9) : Color(red: 0.36, green: 0.5, blue: 1).opacity(0.85), in: Capsule())
            }
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(next.day).font(.system(size: 44, weight: .heavy)).foregroundStyle(.white)
                VStack(alignment: .leading) {
                    Text("\(next.name) · \(next.month.capitalized)").font(.title3.weight(.bold)).foregroundStyle(.white)
                    Text(next.weekday).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                }
            }
            Divider().background(.white.opacity(0.18))
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Emende com").font(.caption).foregroundStyle(.white.opacity(0.78))
                    Text("\(next.vacationDays) dia(s) de férias").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Você ganha").font(.caption).foregroundStyle(.white.opacity(0.78))
                    Text(next.daysGainedLabel).font(.title2.weight(.heavy)).foregroundStyle(accentOrange)
                    Text("\(next.daysOffLabel) seguidos").font(.caption2).foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(22)
        .glassCard(cornerRadius: 28, tint: 0.14)
    }

    var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(appState.vacationDaysUsedThisYear)", label: "dias usados em \(String(currentYear))", color: accentOrange)
            statCard(value: "\(appState.remainingVacationDays)", label: "dias de saldo", color: .white)
            statCard(value: "\(appState.emendas.count)", label: "emendas", color: .white)
        }
    }

    /// Férias registradas em andamento ou por vir — some quando não há nenhuma.
    @ViewBuilder
    var scheduledVacationCard: some View {
        if let vacation = appState.nextScheduledVacation {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let inProgress = calendar.startOfDay(for: vacation.start) <= today
            let daysUntil = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: vacation.start)).day ?? 0
            let gained = appState.daysGained(for: vacation)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("FÉRIAS AGENDADAS").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.75))
                    Spacer()
                    Text(inProgress ? "EM ANDAMENTO" : (daysUntil == 1 ? "AMANHÃ" : "EM \(daysUntil) DIAS"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(red: 0.1, green: 0.06, blue: 0.03))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(accentOrange.opacity(0.9), in: Capsule())
                }
                HStack(spacing: 12) {
                    Image(systemName: inProgress ? "beach.umbrella.fill" : "airplane.departure")
                        .font(.title3)
                        .foregroundStyle(accentOrange)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vacation.rangeLabel).font(.subheadline.weight(.bold)).foregroundStyle(.white)
                        Text("\(vacation.days) dias corridos" + (gained > 0 ? " · +\(gained) de bônus com folgas ao redor" : ""))
                            .font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 22)
        }
    }

    /// O melhor conjunto de emendas que cabe no saldo de férias restante.
    @ViewBuilder
    var yearPlanCard: some View {
        let plan = appState.yearPlan
        if !plan.emendas.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("PLANO DO ANO").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.75))
                    Spacer()
                    Image(systemName: "sparkles").font(.caption).foregroundStyle(accentOrange)
                }
                if plan.mainPeriodReserve > 0 {
                    Text("Reservando \(plan.mainPeriodReserve) dias para as férias principais, sobram \(appState.remainingVacationDays - plan.mainPeriodReserve) dia(s): use \(plan.vacationDaysUsed) em \(plan.emendas.count) emenda(s) e some \(plan.totalDaysOff) dias de descanso.")
                        .font(.footnote).foregroundStyle(.white.opacity(0.85))
                } else {
                    Text("Com \(plan.vacationDaysUsed) do(s) seus \(appState.remainingVacationDays) dia(s) de saldo, você emenda \(plan.emendas.count) feriado(s) e soma \(plan.totalDaysOff) dias de descanso.")
                        .font(.footnote).foregroundStyle(.white.opacity(0.85))
                }
                Divider().background(.white.opacity(0.15))
                ForEach(plan.emendas) { e in
                    HStack {
                        Text("\(e.day) \(e.month.capitalized) · \(e.name)").font(.caption.weight(.semibold)).foregroundStyle(.white)
                        Spacer()
                        Text("\(VacationPlanner.chargedDays(for: e))d → \(e.daysOff)d").font(.caption.weight(.bold)).foregroundStyle(accentOrange)
                    }
                }
                Text("Fracionamento conforme CLT art. 134 §1º: cada período fracionado tem no mínimo 5 dias.")
                    .font(.caption2).foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            .glassCard(cornerRadius: 22)
        }
    }

    func statusBanner(icon: String?, message: String) -> some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon).font(.subheadline).foregroundStyle(accentOrange)
            } else {
                ProgressView().tint(.white)
            }
            Text(message).font(.footnote).foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .glassCard(cornerRadius: 18)
    }

    func statCard(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 26, weight: .heavy)).foregroundStyle(color)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard(cornerRadius: 22)
    }
}

struct EmendaRow: View {
    let emenda: Emenda
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(emenda.month).font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.78))
                Text(emenda.day).font(.system(size: 17, weight: .heavy)).foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)
            .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(emenda.name).font(.subheadline.weight(.bold)).foregroundStyle(.white)
                Text("\(emenda.range) · \(emenda.badge)").font(.caption).foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text("+\(emenda.daysOff)").font(.title3.weight(.heavy)).foregroundStyle(accentOrange)
                Text("dias").font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .glassCard(cornerRadius: 20)
    }
}
