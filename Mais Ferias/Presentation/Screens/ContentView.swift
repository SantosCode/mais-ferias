import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("Início", systemImage: "house.fill") }
                .tag(0)
            EmendasView()
                .tabItem { Label("Emendas", systemImage: "list.bullet") }
                .tag(1)
            CalendarioView()
                .tabItem { Label("Calendário", systemImage: "calendar") }
                .tag(2)
            PerfilView()
                .tabItem { Label("Perfil", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(accentOrange)
        .preferredColorScheme(appState.appearance.colorScheme)
        .task { await appState.loadEmendas() }
    }
}

#Preview {
    let container = try! ModelContainer(for: UserProfile.self, VacationPeriod.self, CachedHoliday.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    ContentView()
        .environment(AppState(modelContext: container.mainContext))
}
