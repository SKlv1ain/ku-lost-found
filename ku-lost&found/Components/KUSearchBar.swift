import SwiftUI

struct KUSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search items or locations…"
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(KUTheme.Palette.primary700)
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
        .padding(.vertical, 9)
        .background(focused ? KUTheme.Palette.white : KUTheme.Palette.primary50)
        .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                .stroke(KUTheme.Palette.primary700.opacity(focused ? 0.18 : 0), lineWidth: 3)
        )
        .animation(.easeOut(duration: 0.2), value: focused)
    }
}
