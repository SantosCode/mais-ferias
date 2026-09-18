import SwiftUI

/// Preferência de aparência do app. O fundo aurora é sempre escuro, mas isto
/// controla a UI desenhada pelo sistema (date pickers, menus, alertas, tab bar)
/// via `preferredColorScheme`.
enum Appearance: String, CaseIterable, Identifiable {
    case automatic
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: return "Automático"
        case .light: return "Claro"
        case .dark: return "Escuro"
        }
    }

    /// `nil` segue o ajuste do sistema.
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
