import SwiftUI

struct RegistrarFeriasView: View {
    @Environment(AppState.self) var appState
    @State private var start: Date
    @State private var end: Date

    init(prefillStart: Date? = nil, prefillEnd: Date? = nil) {
        _start = State(initialValue: prefillStart ?? Date())
        _end = State(initialValue: prefillEnd ?? Date().addingTimeInterval(86400 * 3))
    }

    var hasValidRange: Bool { end >= start }
    var overlapsExisting: Bool { hasValidRange && appState.overlapsExistingVacation(start: start, end: end) }
    var canAdd: Bool { hasValidRange && !overlapsExisting }
    var previewDays: Int { (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1 }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Cadastre os dias de férias que você já tirou ou planeja tirar.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        statCard(value: "\(appState.vacations.count)", label: "período(s)", color: .white)
                        statCard(value: "\(appState.totalVacationDays)", label: "dias de férias registrados", color: accentOrange)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Início").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
                            DatePicker("", selection: $start, displayedComponents: .date)
                                .labelsHidden().datePickerStyle(.compact).tint(accentOrange)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Fim").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
                            DatePicker("", selection: $end, displayedComponents: .date)
                                .labelsHidden().datePickerStyle(.compact).tint(accentOrange)
                        }
                        if overlapsExisting {
                            Label("Esse intervalo tem a mesma data ou cruza um período já registrado.", systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote).foregroundStyle(accentOrange)
                        } else if canAdd {
                            Text("\(previewDays) dias corridos").font(.footnote).foregroundStyle(.white.opacity(0.78))
                        }
                        Button {
                            appState.addVacation(start: start, end: end)
                        } label: {
                            Text("Adicionar período").font(.subheadline.weight(.bold))
                                .foregroundStyle(canAdd ? Color(red: 0.1, green: 0.06, blue: 0.03) : .white.opacity(0.4))
                                .frame(maxWidth: .infinity).frame(height: 48)
                                .background(canAdd ? accentOrange : .white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!canAdd)
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)

                    if !appState.vacations.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PERÍODOS REGISTRADOS").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.5))
                            ForEach(appState.vacations) { v in
                                let gained = appState.daysGained(for: v)
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(v.rangeLabel).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                        Text("\(v.days) dias corridos").font(.caption).foregroundStyle(.white.opacity(0.7))
                                    }
                                    Spacer()
                                    if gained > 0 {
                                        VStack(alignment: .trailing, spacing: 0) {
                                            Text("+\(gained)").font(.subheadline.weight(.heavy)).foregroundStyle(accentOrange)
                                            Text(gained == 1 ? "dia ganho" : "dias ganhos").font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.7))
                                        }
                                        .padding(.trailing, 8)
                                    }
                                    Button {
                                        appState.removeVacation(v)
                                    } label: {
                                        Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.75))
                                            .frame(width: 30, height: 30).background(.white.opacity(0.12), in: Circle())
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                .glassCard(cornerRadius: 18)
                            }
                        }
                    }
                }
                .padding(18)
            }
        }
        .navigationTitle("Registrar férias")
        .navigationBarTitleDisplayMode(.inline)
    }

    func statCard(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 22, weight: .heavy)).foregroundStyle(color)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 18)
    }
}
