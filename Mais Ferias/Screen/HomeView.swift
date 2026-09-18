import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    var next: Emenda { AppState.allEmendas[0] }
    var others: [Emenda] { Array(AppState.allEmendas.dropFirst()) }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Boa tarde").font(.subheadline).foregroundStyle(.white.opacity(0.78))
                            Text("Suas emendas").font(.system(size: 28, weight: .bold))
                        }
                        Spacer()
                        Circle().fill(.white.opacity(0.16)).frame(width: 44, height: 44)
                            .overlay(Text("LS").font(.headline).foregroundStyle(.white))
                            .overlay(Circle().strokeBorder(.white.opacity(0.25)))
                    }
                    .foregroundStyle(.white)

                    heroCard
                    statsRow

                    HStack {
                        Text("Outras emendas").font(.headline).foregroundStyle(.white)
                        Spacer()
                        Text("Ver todas").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.75))
                    }

                    ForEach(others) { e in EmendaRow(emenda: e) }
                }
                .padding(18)
                .padding(.bottom, 20)
            }
        }
    }

    var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("PRÓXIMA EMENDA").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text("NACIONAL").font(.caption2.weight(.bold)).foregroundStyle(Color(red: 0.1, green: 0.06, blue: 0.03))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(accentOrange.opacity(0.9), in: Capsule())
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
                    Text("\(next.daysOff) dias").font(.title2.weight(.heavy)).foregroundStyle(accentOrange)
                }
            }
        }
        .padding(22)
        .glassCard(cornerRadius: 28, tint: 0.14)
    }

    var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(appState.totalVacationDays)", label: "dias usados em 2026", color: accentOrange)
            statCard(value: "\(AppState.allEmendas.count)", label: "emendas disponíveis", color: .white)
        }
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
