import SwiftUI

struct ItemCard: View {
    let item: Item
    var photoURL: URL? = nil
    var reporterName: String? = nil
    var onReporterTap: (() -> Void)? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: KUTheme.Radius.md, style: .continuous)
                        .fill(item.status == .lost ? KUTheme.Palette.accent50 : KUTheme.Palette.primary50)

                    if let photoURL {
                        AsyncImage(url: photoURL) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                Text(item.emoji).font(.system(size: 26))
                            }
                        }
                    } else {
                        Text(item.emoji).font(.system(size: 26))
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.md, style: .continuous))

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
                    if let name = reporterName {
                        Button {
                            onReporterTap?()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 11))
                                Text(name)
                                    .font(Font.Sarabun.medium(11))
                            }
                            .foregroundStyle(KUTheme.Palette.primary700)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KUTheme.Palette.neutral300)
            }
            .padding(14)
            .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                    .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
            )
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
