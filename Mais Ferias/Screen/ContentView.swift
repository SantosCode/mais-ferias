import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Início", systemImage: "house.fill") }
            EmendasView()
                .tabItem { Label("Emendas", systemImage: "list.bullet") }
            CalendarioView()
                .tabItem { Label("Calendário", systemImage: "calendar") }
            PerfilView()
                .tabItem { Label("Perfil", systemImage: "person.fill") }
        }
        .tint(accentOrange)
        .task { await appState.loadEmendas() }
    }
}

#Preview {
    let container = try! ModelContainer(for: UserProfile.self, VacationPeriod.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    ContentView()
        .environment(AppState(modelContext: container.mainContext))
}
