import SwiftUI

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(Font.Sarabun.bold(17))
                .foregroundStyle(KUTheme.Palette.neutral900)
            Spacer()
            if let action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .font(Font.Sarabun.medium(14))
                        .foregroundStyle(KUTheme.Palette.primary700)
                }
            }
        }
        .padding(.bottom, 8)
    }
}
