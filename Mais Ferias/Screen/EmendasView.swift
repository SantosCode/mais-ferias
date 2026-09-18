import SwiftUI

struct EmendasView: View {
    enum Filter: String, CaseIterable { case todos = "Todos", nacional = "Nacional", estadual = "Estadual" }
    @State private var filter: Filter = .todos

    var filtered: [Emenda] {
        switch filter {
        case .todos: return AppState.allEmendas
        case .nacional: return AppState.allEmendas.filter { $0.isNational }
        case .estadual: return AppState.allEmendas.filter { !$0.isNational }
        }
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    HStack { Text("Emendas 2026").font(.system(size: 28, weight: .bold)).foregroundStyle(.white); Spacer() }

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
                            }
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 22)
                        .shadow(color: .black.opacity(0.3), radius: 14, y: 6)
                    }
                }
                .padding(18)
            }
        }
    }
}
