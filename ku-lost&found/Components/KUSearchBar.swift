import SwiftUI

struct KUSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search items or locations…"
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(KUTheme.Palette.neutral600)
            TextField(placeholder, text: $text)
                .focused($focused)
                .font(Font.Sarabun.regular(15))
                .foregroundStyle(KUTheme.Palette.neutral900)
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(KUTheme.Palette.neutral400)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(KUTheme.Palette.neutral100)
        .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                .stroke(focused ? KUTheme.Palette.neutral900 : KUTheme.Palette.neutral200,
                        lineWidth: focused ? 1.5 : 1)
        )
        .animation(.easeOut(duration: 0.18), value: focused)
    }
}
