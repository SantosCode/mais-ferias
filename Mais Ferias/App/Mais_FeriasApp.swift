//
//  Mais_FeriasApp.swift
//  Mais Ferias
//
//  Created by Luis Santos on 15/09/26.
//

import SwiftUI
import SwiftData
import UserNotifications

/// Encaminha o toque em uma notificação de emenda para a aba Emendas.
private final class NotificationTapHandler: NSObject, UNUserNotificationCenterDelegate {
    var onTap: (@Sendable () -> Void)?

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        onTap?()
    }

    /// Exibe o lembrete mesmo com o app em primeiro plano.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

@main
struct Mais_FeriasApp: App {
    var sharedModelContainer: ModelContainer
    @State private var appState: AppState
    @State private var showSplash = true
    private let notificationTapHandler = NotificationTapHandler()

    init() {
        let schema = Schema([UserProfile.self, VacationPeriod.self, CachedHoliday.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        sharedModelContainer = container
        let state = AppState(modelContext: container.mainContext)
        _appState = State(initialValue: state)

        UNUserNotificationCenter.current().delegate = notificationTapHandler
        notificationTapHandler.onTap = {
            Task { @MainActor in state.selectedTab = 1 }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.hasOnboarded {
                    ContentView()
                } else {
                    OnboardingView()
                }
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .environment(appState)
            .task {
                // Mantém o splash por um instante enquanto o primeiro carregamento começa por trás.
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeOut(duration: 0.6)) { showSplash = false }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
