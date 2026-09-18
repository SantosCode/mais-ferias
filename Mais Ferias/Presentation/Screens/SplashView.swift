import SwiftUI

/// Splash de abertura: o logo do app sobre o fundo aurora, exibido brevemente
/// enquanto a UI principal carrega por trás; o fade-out é feito por `Mais_FeriasApp`.
struct SplashView: View {
    @State private var isVisible = false
    @State private var isGlowing = false

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 20) {
                Image(systemName: "beach.umbrella.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [accentOrange, Color(red: 1, green: 0.42, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 148, height: 148)
                    .glassCard(cornerRadius: 44, tint: 0.14)
                    .shadow(color: accentOrange.opacity(isGlowing ? 0.5 : 0.25), radius: isGlowing ? 44 : 26, y: 10)

                VStack(spacing: 6) {
                    Text("Mais Férias")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Emende feriados e descanse mais")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .scaleEffect(isVisible ? 1 : 0.86)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.25)) { isVisible = true }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { isGlowing = true }
        }
    }
}

#Preview {
    SplashView()
}
