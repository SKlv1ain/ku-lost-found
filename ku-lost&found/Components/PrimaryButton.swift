import SwiftUI

struct PrimaryButton: View {
    let label: String
    var icon: String? = nil
    var color: Color = KUTheme.Palette.primary700
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(label)
                    .font(Font.Sarabun.semibold(16))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .background(color, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
            .shadow(color: color.opacity(0.25), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(KUPressStyle())
    }
}

struct KUPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
