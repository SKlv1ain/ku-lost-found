import SwiftUI

struct StatusBadge: View {
    let status: ItemStatus
    @State private var pulse = false

    private var palette: (bg: Color, fg: Color) {
        switch status {
        case .found:   return (KUTheme.Palette.successBg, KUTheme.Palette.success)
        case .lost:    return (KUTheme.Palette.warningBg, KUTheme.Palette.lostText)
        case .claimed:  return (KUTheme.Palette.infoBg,    KUTheme.Palette.info)
        case .expired:  return (KUTheme.Palette.dangerBg,  KUTheme.Palette.danger)
        case .returned: return (KUTheme.Palette.successBg, KUTheme.Palette.success)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(palette.fg)
                .frame(width: 6, height: 6)
                .scaleEffect(status == .lost && pulse ? 1.5 : 1)
                .opacity(status == .lost && pulse ? 0.6 : 1)
                .animation(status == .lost
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                    value: pulse)
            Text(status.label)
                .font(Font.Sarabun.bold(11))
                .foregroundStyle(palette.fg)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(palette.bg, in: RoundedRectangle(cornerRadius: KUTheme.Radius.sm, style: .continuous))
        .onAppear { pulse = true }
    }
}
