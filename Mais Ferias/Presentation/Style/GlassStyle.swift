import SwiftUI

let accentOrange = Color(red: 1, green: 0.54, blue: 0.36)

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 22
    var tint: Double = 0.12
    var borderOpacity: Double = 0.22

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white.opacity(tint))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.4), .white.opacity(borderOpacity)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.8
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 22, tint: Double = 0.12) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius, tint: tint))
    }
}

/// Fundo aurora com tema de férias usado atrás de todas as telas.
struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.14, green: 0.10, blue: 0.26), Color(red: 0.09, green: 0.07, blue: 0.17), Color(red: 0.04, green: 0.03, blue: 0.11)],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(colors: [Color(red: 1, green: 0.70, blue: 0.48).opacity(0.55), .clear], center: .init(x: 0.12, y: 0.06), startRadius: 0, endRadius: 380)
            RadialGradient(colors: [Color(red: 1, green: 0.42, blue: 0.55).opacity(0.4), .clear], center: .init(x: 0.88, y: 0.14), startRadius: 0, endRadius: 380)
            RadialGradient(colors: [Color(red: 0.36, green: 0.50, blue: 1).opacity(0.35), .clear], center: .init(x: 0.15, y: 0.7), startRadius: 0, endRadius: 400)
            RadialGradient(colors: [Color(red: 0.18, green: 0.83, blue: 0.78).opacity(0.3), .clear], center: .init(x: 0.92, y: 0.88), startRadius: 0, endRadius: 380)
        }
        .ignoresSafeArea()
    }
}
