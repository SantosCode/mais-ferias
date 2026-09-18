import SwiftUI

struct EmendasView: View {
    enum Filter: String, CaseIterable { case todos = "Todos", nacional = "Nacional", estadual = "Estadual" }
    @Environment(AppState.self) var appState
    @State private var filter: Filter = .todos
    @State private var exportMessage: String?

    var filtered: [Emenda] {
        switch filter {
        case .todos: return appState.emendas
        case .nacional: return appState.emendas.filter { $0.isNational }
        case .estadual: return appState.emendas.filter { !$0.isNational }
        }
    }

    /// Rótulo da janela rolante de 12 meses coberta pela lista, ex.: "Set 2026 – Ago 2027".
    private var periodLabel: String {
        let calendar = Calendar(identifier: .gregorian)
        let (start, end) = AppState.twelveMonthWindow(from: Date(), calendar: calendar)
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: end) ?? end
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "MMM yyyy"
        func label(_ date: Date) -> String {
            f.string(from: date).replacingOccurrences(of: ".", with: "").capitalized
        }
        return "\(label(start)) – \(label(lastMonth))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Emendas").font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
                                Text(periodLabel).font(.subheadline).foregroundStyle(.white.opacity(0.72))
                            }
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            ForEach(Filter.allCases, id: \.self) { f in
                                Text(f.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(filter == f ? Color(red: 0.1, green: 0.06, blue: 0.03) : .white.opacity(0.75))
                                    .padding(.horizontal, 18).frame(height: 40)
                                    .background(filter == f ? accentOrange : .white.opacity(0.12), in: Capsule())
                                    .overlay(Capsule().strokeBorder(.white.opacity(filter == f ? 0 : 0.2)))
                                    .onTapGesture { filter = f }
                            }
                            Spacer()
                        }

                        ForEach(filtered) { e in
                            if let suggestion = appState.suggestedVacationPeriod(for: e) {
                                NavigationLink {
                                    RegistrarFeriasView(prefillStart: suggestion.start, prefillEnd: suggestion.end)
                                } label: {
                                    card(e, tappable: true)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        Task {
                                            let added = await CalendarExporter.addVacation(named: e.name, from: suggestion.start, to: suggestion.end)
                                            exportMessage = added
                                                ? "Férias de \(e.name) adicionadas ao calendário."
                                                : "Não foi possível adicionar. Verifique a permissão de calendário nos Ajustes."
                                        }
                                    } label: {
                                        Label("Adicionar férias ao calendário", systemImage: "calendar.badge.plus")
                                    }
                                }
                            } else {
                                card(e, tappable: false)
                            }
                        }
                    }
                    .padding(18)
                }
                .refreshable { await appState.loadEmendas() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Calendário", isPresented: Binding(get: { exportMessage != nil }, set: { if !$0 { exportMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportMessage ?? "")
            }
        }
    }

    private func card(_ e: Emenda, tappable: Bool) -> some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 12) {
                    VStack(spacing: 0) {
                        Text(e.month).font(.system(size: 9.5, weight: .bold)).foregroundStyle(.white.opacity(0.78))
                        Text(e.day).font(.system(size: 16, weight: .heavy)).foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.name).font(.subheadline.weight(.bold)).foregroundStyle(.white)
                        Text(e.weekday).font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                }
                Spacer()
                Text(e.badge.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(e.isNational ? Color(red: 0.1, green: 0.06, blue: 0.03) : .white)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(e.isNational ? accentOrange.opacity(0.9) : Color(red: 0.36, green: 0.5, blue: 1).opacity(0.85), in: Capsule())
            }
            Divider().background(.white.opacity(0.15))
            HStack {
                Text("\(e.range) · use \(e.vacationDays) dia(s) de férias").font(.footnote).foregroundStyle(.white.opacity(0.78))
                Spacer()
                Text("\(e.daysOff) dias").font(.title3.weight(.heavy)).foregroundStyle(accentOrange)
                if tappable {
                    Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 22)
        .shadow(color: .black.opacity(0.3), radius: 14, y: 6)
    }
}
