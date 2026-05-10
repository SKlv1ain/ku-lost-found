import SwiftUI

struct BrowseScreen: View {
    var itemsVM: ItemsViewModel
    var onItem: (Item) -> Void

    @State private var activeStatus: ItemStatus? = nil
    @State private var activeCategory: ItemCategory = .all

    private let statuses: [ItemStatus?] = [nil, .found, .lost, .claimed]

    private var filtered: [Item] {
        itemsVM.items.filter { i in
            (activeStatus == nil || i.status == activeStatus)
            && (activeCategory == .all || i.category == activeCategory)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(statuses, id: \.self) { st in
                        StatusPill(label: st?.label ?? "All", isActive: activeStatus == st) {
                            activeStatus = st
                        }
                    }
                    Spacer(minLength: 0)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SampleData.categories, id: \.self) { c in
                            CategoryChip(label: c.label, isActive: activeCategory == c) {
                                activeCategory = c
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(KUTheme.Palette.white)
            .overlay(alignment: .bottom) {
                Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "\(filtered.count) item\(filtered.count == 1 ? "" : "s")")
                    ForEach(filtered) { item in
                        ItemCard(item: item) { onItem(item) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 80)
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
    }

    private var navBar: some View {
        ZStack {
            Text("Browse Items")
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
}

#Preview { BrowseScreen(itemsVM: ItemsViewModel(), onItem: { _ in }) }
