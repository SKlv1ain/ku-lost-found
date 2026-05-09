import SwiftUI

struct ItemCard: View {
    let item: Item
    let onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: KUTheme.Radius.md, style: .continuous)
                        .fill(item.status == .lost ? KUTheme.Palette.accent50 : KUTheme.Palette.primary50)
                    Text(item.emoji).font(.system(size: 26))
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(Font.Sarabun.semibold(15))
                        .foregroundStyle(KUTheme.Palette.neutral900)
                        .lineLimit(1)
                    Text(item.location)
                        .font(Font.Sarabun.regular(12))
                        .foregroundStyle(KUTheme.Palette.neutral600)
                        .lineLimit(1)
                        .padding(.bottom, 4)
                    HStack(spacing: 8) {
                        StatusBadge(status: item.status)
                        Text(item.time)
                            .font(Font.Sarabun.regular(11))
                            .foregroundStyle(KUTheme.Palette.neutral400)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KUTheme.Palette.neutral300)
            }
            .padding(14)
            .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
            .kuShadow()
        }
        .buttonStyle(KUTappableStyle())
    }
}

struct KUTappableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.85), value: configuration.isPressed)
    }
}
