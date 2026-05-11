import SwiftUI

struct QuickActionCard: View {
    enum Kind { case lost, found }
    let kind: Kind
    let action: () -> Void

    private var emoji: String { kind == .lost ? "😟" : "🙌" }
    private var label: String { kind == .lost ? "I lost something" : "I found something" }
    private var bg: Color { kind == .lost ? KUTheme.Palette.accent50 : KUTheme.Palette.primary50 }
    private var border: Color { kind == .lost ? KUTheme.Palette.accent500 : KUTheme.Palette.primary700 }
    private var fg: Color { kind == .lost ? KUTheme.Palette.accent700 : KUTheme.Palette.primary700 }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 28))
                Text(label)
                    .font(Font.Sarabun.bold(13))
                    .foregroundStyle(fg)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(bg, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                    .stroke(border, lineWidth: 1.5)
            )
        }
        .buttonStyle(KUTappableStyle())
    }
}
