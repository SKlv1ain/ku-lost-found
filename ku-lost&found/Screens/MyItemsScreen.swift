import SwiftUI

struct MyItemsScreen: View {
    var onItem: (Item) -> Void
    var onReport: () -> Void

    private var myItems: [Item] {
        SampleData.items.filter { [1, 4].contains($0.id) }
    }

    private var locationGroups: [(location: String, items: [Item], accent: Color)] {
        let buckets = Dictionary(grouping: myItems, by: { $0.location })
        return buckets.map { loc, items in
            let accent = items.first?.status == .lost
                ? KUTheme.Palette.lostText
                : KUTheme.Palette.primary700
            return (loc, items, accent)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(myItems.count)")
                                .font(Font.Sarabun.bold(48))
                                .foregroundStyle(KUTheme.Palette.neutral900)
                            Text("Reports")
                                .font(Font.Sarabun.medium(16))
                                .foregroundStyle(KUTheme.Palette.neutral600)
                        }
                        Spacer()
                        Button(action: onReport) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(KUTheme.Palette.neutral900)
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 24, height: 24)
                                Text("New report")
                                    .font(Font.Sarabun.semibold(14))
                                    .foregroundStyle(KUTheme.Palette.neutral900)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .overlay(Capsule().stroke(KUTheme.Palette.neutral300, lineWidth: 1.5))
                        }
                        .buttonStyle(KUTappableStyle())
                    }

                    ForEach(locationGroups, id: \.location) { group in
                        locationCard(location: group.location, items: group.items, accent: group.accent)
                    }
                }
                .padding(16)
                .padding(.bottom, 80)
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
    }

    private var navBar: some View {
        ZStack {
            Text("My Items")
                .font(Font.Sarabun.semibold(17))
                .foregroundStyle(KUTheme.Palette.neutral900)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(KUTheme.Palette.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
        }
    }

    private func locationCard(location: String, items: [Item], accent: Color) -> some View {
        Button { if let first = items.first { onItem(first) } } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    StripedGradient(accent: accent)
                        .frame(height: 160)
                    HStack {
                        Text(items.first?.status == .lost ? "Lost" : "Found")
                            .font(Font.Sarabun.bold(11))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.95), in: Capsule())
                            .padding(12)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        VStack { Spacer()
                            Text(items.first?.emoji ?? "📦")
                                .font(.system(size: 64))
                                .padding(16)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(location)
                        .font(Font.Sarabun.bold(17))
                        .foregroundStyle(KUTheme.Palette.neutral900)
                    Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                        .font(Font.Sarabun.regular(13))
                        .foregroundStyle(KUTheme.Palette.neutral600)
                }
                .padding(.top, 12)
            }
        }
        .buttonStyle(KUTappableStyle())
    }
}

private struct StripedGradient: View {
    let accent: Color
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [accent.opacity(0.18), accent.opacity(0.45)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            GeometryReader { geo in
                Path { p in
                    let step: CGFloat = 18
                    let h = geo.size.height
                    let w = geo.size.width
                    var x: CGFloat = -h
                    while x < w + h {
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x + h, y: h))
                        x += step
                    }
                }
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
        }
    }
}

#Preview { MyItemsScreen(onItem: { _ in }, onReport: {}) }
