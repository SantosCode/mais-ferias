//
//  Mais_FeriasApp.swift
//  Mais Ferias
//
//  Created by Luis Santos on 15/09/26.
//

import SwiftUI
import SwiftData

@main
struct Mais_FeriasApp: App {
    var sharedModelContainer: ModelContainer
    @State private var appState: AppState

    init() {
        let schema = Schema([UserProfile.self, VacationPeriod.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        sharedModelContainer = container
        _appState = State(initialValue: AppState(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
