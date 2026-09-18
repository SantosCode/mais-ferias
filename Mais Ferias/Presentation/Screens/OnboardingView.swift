import SwiftUI

/// Configuração do primeiro launch: nome, estado, jornada e orçamentos de férias.
/// Exibida uma única vez (controlado por `AppState.hasOnboarded`).
struct OnboardingView: View {
    @Environment(AppState.self) var appState
    @State private var name = ""
    @State private var uf: BrazilState = .SP
    @State private var schedule: WorkSchedule = .weekdays
    @State private var desiredDays = 5
    @State private var allowance = 30

    private var canStart: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "beach.umbrella.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(LinearGradient(colors: [accentOrange, Color(red: 1, green: 0.42, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("Bem-vindo ao Mais Férias").font(.title2.weight(.bold)).foregroundStyle(.white)
                        Text("Conte um pouco sobre você para calcularmos as melhores emendas.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Seu nome").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
                            TextField("Como podemos te chamar?", text: $name)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Seu estado").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
                            Picker("Estado", selection: $uf) {
                                ForEach(BrazilState.allCases.sorted { $0.fullName < $1.fullName }) { state in
                                    Text(state.fullName).tag(state)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accentOrange)
                            Text("Os feriados estaduais da sua UF vêm da internet. Sem conexão, mostraremos apenas os nacionais até a próxima sincronização.")
                                .font(.caption2).foregroundStyle(.white.opacity(0.55))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Dias de trabalho").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
                            Picker("Dias de trabalho", selection: $schedule) {
                                ForEach(WorkSchedule.allCases) { Text($0.label).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        Stepper(value: $desiredDays, in: 1...30) {
                            HStack {
                                Text("Dias por emenda").font(.subheadline).foregroundStyle(.white)
                                Spacer()
                                Text("\(desiredDays)").font(.subheadline.weight(.bold)).foregroundStyle(accentOrange)
                            }
                        }

                        Stepper(value: $allowance, in: 1...60) {
                            HStack {
                                Text("Saldo anual de férias").font(.subheadline).foregroundStyle(.white)
                                Spacer()
                                Text("\(allowance)").font(.subheadline.weight(.bold)).foregroundStyle(accentOrange)
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 22)

                    Button {
                        appState.userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        appState.workSchedule = schedule
                        appState.desiredVacationDays = desiredDays
                        appState.annualVacationAllowance = allowance
                        appState.selectedUF = uf
                        withAnimation(.easeOut(duration: 0.4)) { appState.hasOnboarded = true }
                    } label: {
                        Text("Começar")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(canStart ? Color(red: 0.1, green: 0.06, blue: 0.03) : .white.opacity(0.4))
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(canStart ? accentOrange : .white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canStart)
                }
                .padding(18)
            }
        }
        .onAppear {
            name = appState.userName == "Luís Santos" ? "" : appState.userName
            uf = appState.selectedUF
            schedule = appState.workSchedule
            desiredDays = appState.desiredVacationDays
            allowance = appState.annualVacationAllowance
        }
    }
}
