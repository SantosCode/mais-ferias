import SwiftUI

struct EstadoPickerView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) var dismiss
    @State private var search = ""

    var filtered: [BrazilState] {
        search.isEmpty ? BrazilState.allCases.sorted { $0.fullName < $1.fullName }
        : BrazilState.allCases.filter { $0.fullName.localizedCaseInsensitiveContains(search) }.sorted { $0.fullName < $1.fullName }
    }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                Text("Usamos seu estado para mostrar os feriados estaduais certos nas suas emendas.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 18).padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.element) { idx, uf in
                            Button {
                                appState.selectedUF = uf
                                dismiss()
                            } label: {
                                HStack {
                                    Text(uf.fullName).font(.body).foregroundStyle(.white)
                                    Spacer()
                                    Text(uf.rawValue).font(.footnote).foregroundStyle(.white.opacity(0.55))
                                    if uf == appState.selectedUF {
                                        Circle().fill(accentOrange).frame(width: 22, height: 22)
                                            .overlay(Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Color(red: 0.1, green: 0.06, blue: 0.03)))
                                    }
                                }
                                .padding(.horizontal, 16).frame(minHeight: 54)
                            }
                            .buttonStyle(.plain)
                            if idx < filtered.count - 1 { Divider().background(.white.opacity(0.08)).padding(.leading, 16) }
                        }
                    }
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal, 18)
                }
            }
            .padding(.top, 8)
        }
        .searchable(text: $search, prompt: "Buscar estado")
        .navigationTitle("Seu estado")
        .navigationBarTitleDisplayMode(.inline)
    }
}
