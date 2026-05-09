import SwiftUI

struct ItemDetailScreen: View {
    let item: Item
    let onBack: () -> Void

    @State private var claimed = false

    var body: some View {
        VStack(spacing: 0) {
            navBar
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero
                    HStack(spacing: 10) {
                        Text(item.title)
                            .font(Font.Sarabun.bold(22))
                            .foregroundStyle(KUTheme.Palette.neutral900)
                        StatusBadge(status: item.status)
                    }
                    metaCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this item")
                            .font(Font.Sarabun.semibold(15))
                            .foregroundStyle(KUTheme.Palette.neutral700)
                        Text(item.description)
                            .font(Font.Sarabun.regular(15))
                            .foregroundStyle(KUTheme.Palette.neutral700)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }

                    cta
                        .padding(.top, 8)
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
    }

    private var navBar: some View {
        ZStack {
            Text("Item Details")
                .font(Font.Sarabun.semibold(17))
                .foregroundStyle(KUTheme.Palette.neutral900)
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                        Text("Back").font(Font.Sarabun.regular(17))
                    }
                    .foregroundStyle(KUTheme.Palette.primary700)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(KUTheme.Palette.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
        }
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous)
                .fill(item.status == .lost ? KUTheme.Palette.accent50 : KUTheme.Palette.primary50)
            Text(item.emoji).font(.system(size: 110))
        }
        .frame(height: 220)
    }

    private var metaCard: some View {
        VStack(spacing: 0) {
            metaRow(icon: "mappin.and.ellipse", label: "Location", value: item.location)
            divider
            metaRow(icon: "clock", label: "Reported", value: item.time)
            divider
            metaRow(icon: "number", label: "Item ID", value: String(format: "KU-%05d", item.id), monospaced: true)
        }
        .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
        .kuShadow()
    }

    private var divider: some View {
        Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1).padding(.leading, 48)
    }

    private func metaRow(icon: String, label: String, value: String, monospaced: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(KUTheme.Palette.primary700)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Font.Sarabun.regular(12))
                    .foregroundStyle(KUTheme.Palette.neutral400)
                Text(value)
                    .font(monospaced ? .system(size: 14, design: .monospaced) : Font.Sarabun.medium(15))
                    .foregroundStyle(KUTheme.Palette.neutral900)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    @ViewBuilder
    private var cta: some View {
        if item.status == .claimed {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text("This item has already been claimed.")
                    .font(Font.Sarabun.medium(14))
            }
            .foregroundStyle(KUTheme.Palette.info)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KUTheme.Palette.infoBg, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
        } else if claimed {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Claim submitted!")
                    .font(Font.Sarabun.semibold(15))
            }
            .foregroundStyle(KUTheme.Palette.success)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KUTheme.Palette.successBg, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
            .transition(.scale.combined(with: .opacity))
        } else {
            PrimaryButton(
                label: item.status == .lost ? "I found this item" : "This is mine",
                icon: item.status == .lost ? "hand.raised.fill" : "hand.point.up.left.fill",
                color: item.status == .lost ? KUTheme.Palette.accent700 : KUTheme.Palette.primary700
            ) {
                withAnimation(.spring()) { claimed = true }
            }
        }
    }
}

#Preview {
    ItemDetailScreen(item: SampleData.items[0], onBack: {})
}
