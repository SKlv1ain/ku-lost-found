import SwiftUI

// Outlined pill (status filter on Home)
struct StatusPill: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Font.Sarabun.semibold(13))
                .foregroundStyle(isActive ? KUTheme.Palette.primary700 : KUTheme.Palette.neutral600)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(isActive ? KUTheme.Palette.primary50 : KUTheme.Palette.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isActive ? KUTheme.Palette.primary700 : KUTheme.Palette.neutral300,
                        lineWidth: 1.5)
                )
        }
        .buttonStyle(KUTappableStyle())
    }
}

// Solid category chip (horizontal scroll on Home)
struct CategoryChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Font.Sarabun.medium(13))
                .foregroundStyle(isActive ? .white : KUTheme.Palette.neutral700)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(isActive ? KUTheme.Palette.primary700 : KUTheme.Palette.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isActive ? Color.clear : KUTheme.Palette.neutral200,
                        lineWidth: 1)
                )
        }
        .buttonStyle(KUTappableStyle())
    }
}
