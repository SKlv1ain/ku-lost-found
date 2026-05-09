import SwiftUI

// Animated magnifying-glass logo from HomeScreen.jsx (inline SVG).
struct LostFoundLogo: View {
    @State private var bob = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(KUTheme.Palette.neutral900)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(KUTheme.Palette.accent500)
                .offset(x: -2, y: -2)
        }
        .frame(width: 40, height: 40)
        .rotationEffect(.degrees(bob ? 3 : -3))
        .animation(.easeInOut(duration: 2.25).repeatForever(autoreverses: true), value: bob)
        .onAppear { bob = true }
    }
}
