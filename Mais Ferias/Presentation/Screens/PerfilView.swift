import SwiftUI

struct PerfilView: View {
    @Environment(AppState.self) var appState
    @State private var isEditingName = false
    @State private var draftName = ""

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return "v\(version)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        userCard

                        section(title: "Preferências") {
                            NavigationLink { EstadoPickerView() } label: {
                                row(label: "Estado", value: appState.selectedUF.fullName)
                            }
                            rowDivider
                            Menu {
                                ForEach(WorkSchedule.allCases) { schedule in
                                    Button {
                                        appState.workSchedule = schedule
                                    } label: {
                                        if schedule == appState.workSchedule {
                                            Label(schedule.label, systemImage: "checkmark")
                                        } else {
                                            Text(schedule.label)
                                        }
                                    }
                                }
                            } label: {
                                row(label: "Dias de trabalho", value: appState.workSchedule.label)
                            }
                            rowDivider
                            Stepper(
                                value: Binding(get: { appState.desiredVacationDays }, set: { appState.desiredVacationDays = $0 }),
                                in: 1...30
                            ) {
                                HStack {
                                    Text("Dias de férias desejados").font(.body).foregroundStyle(.white)
                                    Spacer()
                                    Text("\(appState.desiredVacationDays) dia(s)").font(.subheadline).foregroundStyle(.white.opacity(0.72))
                                }
                            }
                            .padding(.horizontal, 16).frame(minHeight: 54)
                            rowDivider
                            Stepper(
                                value: Binding(get: { appState.annualVacationAllowance }, set: { appState.annualVacationAllowance = $0 }),
                                in: 1...60
                            ) {
                                HStack {
                                    Text("Saldo anual de férias").font(.body).foregroundStyle(.white)
                                    Spacer()
                                    Text("\(appState.annualVacationAllowance) dia(s)").font(.subheadline).foregroundStyle(.white.opacity(0.72))
                                }
                            }
                            .padding(.horizontal, 16).frame(minHeight: 54)
                            rowDivider
                            NavigationLink { RegistrarFeriasView() } label: {
                                row(label: "Minhas férias", value: "\(appState.vacations.count) registrada(s)")
                            }
                            rowDivider
                            Toggle(isOn: Binding(get: { appState.notificationsEnabled }, set: { appState.notificationsEnabled = $0 })) {
                                Text("Notificações de emendas").font(.body).foregroundStyle(.white)
                            }
                            .tint(accentOrange)
                            .padding(.horizontal, 16).frame(minHeight: 54)
                            rowDivider
                            Menu {
                                ForEach(Appearance.allCases) { appearance in
                                    Button {
                                        appState.appearance = appearance
                                    } label: {
                                        if appearance == appState.appearance {
                                            Label(appearance.label, systemImage: "checkmark")
                                        } else {
                                            Text(appearance.label)
                                        }
                                    }
                                }
                            } label: {
                                row(label: "Modo escuro", value: appState.appearance.label)
                            }
                        }

                        section(title: "Sobre") {
                            NavigationLink { AjudaView() } label: {
                                row(label: "Central de ajuda", value: "")
                            }
                            rowDivider
                            NavigationLink { SobreView() } label: {
                                row(label: "Sobre o Mais Férias", value: appVersion)
                            }
                        }

                        Text("O cálculo de emendas segue o art. 134, §3º da CLT (Lei nº 13.467/2017): as férias não podem começar nos dois dias que antecedem um feriado ou o descanso semanal remunerado. Fonte: tst.jus.br/ferias1")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.horizontal, 8)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Perfil")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .alert("Editar nome", isPresented: $isEditingName) {
            TextField("Seu nome", text: $draftName)
            Button("Salvar") {
                let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { appState.userName = trimmed }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esse nome aparece na saudação da tela inicial e no seu perfil.")
        }
    }

    var userCard: some View {
        Button {
            draftName = appState.userName
            isEditingName = true
        } label: {
            HStack(spacing: 16) {
                Circle().fill(LinearGradient(colors: [accentOrange, Color(red: 1, green: 0.42, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .overlay(Text(appState.initials).font(.title3.weight(.heavy)).foregroundStyle(Color(red: 0.1, green: 0.06, blue: 0.03)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.userName).font(.title3.weight(.bold)).foregroundStyle(.white)
                    Text("\(appState.selectedUF.fullName) · \(appState.selectedUF.rawValue)").font(.subheadline).foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                Image(systemName: "pencil").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.75))
                    .frame(width: 32, height: 32).background(.white.opacity(0.14), in: Circle())
            }
            .padding(20)
            .glassCard(cornerRadius: 26)
        }
        .buttonStyle(.plain)
    }

    var rowDivider: some View {
        Divider().background(.white.opacity(0.08)).padding(.leading, 16)
    }

    func section(title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.5)).padding(.leading, 6)
            VStack(spacing: 0) { rows() }.glassCard(cornerRadius: 20)
        }
    }

    func row(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.body).foregroundStyle(.white)
            Spacer()
            if !value.isEmpty { Text(value).font(.subheadline).foregroundStyle(.white.opacity(0.72)) }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 16).frame(minHeight: 54)
        .contentShape(Rectangle())
    }
}

struct AjudaView: View {
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 14) {
                    helpCard(
                        question: "O que é uma emenda?",
                        answer: "É a folga estendida que você ganha ao ligar um feriado aos dias livres mais próximos usando poucos dias de férias — por exemplo, um feriado na quinta emendado até o fim de semana."
                    )
                    helpCard(
                        question: "Como o período sugerido é calculado?",
                        answer: "Sugerimos o menor número de dias de férias que conecta o feriado a um bloco de dias livres, respeitando o art. 134, §3º da CLT: as férias não podem começar na sexta, no sábado nem nos dois dias que antecedem um feriado."
                    )
                    helpCard(
                        question: "Para que servem os \"Dias de férias desejados\"?",
                        answer: "É o máximo de dias que você aceita usar em uma única emenda. Quando esse número é maior que o mínimo legal, a sugestão cresce para frente, absorvendo fins de semana e aumentando a folga total."
                    )
                    helpCard(
                        question: "O que conta como dia livre?",
                        answer: "Depende dos seus \"Dias de trabalho\" no perfil: para quem trabalha de segunda a sexta, sábados e domingos são livres. Quem trabalha todos os dias só folga no próprio feriado ou tirando férias."
                    )
                    helpCard(
                        question: "De onde vêm os feriados?",
                        answer: "Buscamos os feriados nacionais e estaduais da UF escolhida no perfil, cobrindo os próximos 12 meses a partir do mês atual."
                    )
                }
                .padding(18)
            }
        }
        .navigationTitle("Central de ajuda")
        .navigationBarTitleDisplayMode(.inline)
    }

    func helpCard(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question).font(.subheadline.weight(.bold)).foregroundStyle(.white)
            Text(answer).font(.footnote).foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard(cornerRadius: 20)
    }
}

struct SobreView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Image(systemName: "beach.umbrella.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(accentOrange)
                        Text("Mais Férias").font(.title2.weight(.bold)).foregroundStyle(.white)
                        Text("Versão \(version) (\(build))").font(.caption).foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .glassCard(cornerRadius: 26)

                    Text("Planejador de férias que encontra as melhores emendas entre os feriados nacionais e estaduais e os seus dias livres, maximizando o descanso com o menor gasto de dias de férias.")
                        .font(.footnote).foregroundStyle(.white.opacity(0.78))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .glassCard(cornerRadius: 20)

                    VStack(spacing: 0) {
                        linkRow(label: "Regras de férias (CLT)", detail: "tst.jus.br", url: "https://www.tst.jus.br/ferias1")
                        Divider().background(.white.opacity(0.08)).padding(.leading, 16)
                        linkRow(label: "Fonte dos feriados", detail: "feriadosapi.com", url: "https://feriadosapi.com")
                    }
                    .glassCard(cornerRadius: 20)
                }
                .padding(18)
            }
        }
        .navigationTitle("Sobre")
        .navigationBarTitleDisplayMode(.inline)
    }

    func linkRow(label: String, detail: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(label).font(.body).foregroundStyle(.white)
                Spacer()
                Text(detail).font(.subheadline).foregroundStyle(.white.opacity(0.72))
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 16).frame(minHeight: 54)
            .contentShape(Rectangle())
        }
    }
}
