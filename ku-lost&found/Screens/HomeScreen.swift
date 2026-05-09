import SwiftUI

struct HomeScreen: View {
    var onItem: (Item) -> Void
    var onReport: (ItemStatus) -> Void

    @State private var search = ""
    @State private var activeStatus: ItemStatus? = nil   // nil == "all"
    @State private var activeCategory: ItemCategory = .all

    private let statuses: [ItemStatus?] = [nil, .found, .lost, .claimed]

    private var filtered: [Item] {
        SampleData.items.filter { item in
            let q = search.lowercased()
            let qOk = q.isEmpty
                || item.title.lowercased().contains(q)
                || item.location.lowercased().contains(q)
            let stOk = activeStatus == nil || item.status == activeStatus
            let catOk = activeCategory == .all || item.category == activeCategory
            return qOk && stOk && catOk
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        QuickActionCard(kind: .lost)  { onReport(.lost) }
                        QuickActionCard(kind: .found) { onReport(.found) }
                    }
                    .padding(.bottom, 22)

                    HStack(spacing: 8) {
                        ForEach(statuses, id: \.self) { st in
                            StatusPill(
                                label: st?.label ?? "All",
                                isActive: activeStatus == st
                            ) { activeStatus = st }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 10)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SampleData.categories, id: \.self) { c in
                                CategoryChip(
                                    label: c.rawValue,
                                    isActive: activeCategory == c
                                ) { activeCategory = c }
                            }
                        }
                    }
                    .padding(.bottom, 14)

                    SectionHeader(title: "\(filtered.count) item\(filtered.count == 1 ? "" : "s")")

                    if filtered.isEmpty {
                        VStack(spacing: 8) {
                            Text("🔍").font(.system(size: 36))
                            Text("No matching items").font(Font.Sarabun.medium(15))
                            Text("Try a different filter or search").font(Font.Sarabun.regular(13))
                        }
                        .foregroundStyle(KUTheme.Palette.neutral400)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filtered) { item in
                                ItemCard(item: item) { onItem(item) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 80)
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    LostFoundLogo()
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Lost & Found")
                            .font(Font.Sarabun.bold(20))
                            .foregroundStyle(KUTheme.Palette.neutral900)
                        Rectangle()
                            .fill(KUTheme.Palette.accent500)
                            .frame(width: 56, height: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(KUTheme.Palette.neutral900)
                        .frame(width: 38, height: 38)
                        .background(KUTheme.Palette.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            KUSearchBar(text: $search)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(KUTheme.Palette.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
        }
    }
}

#Preview {
    HomeScreen(onItem: { _ in }, onReport: { _ in })
}
