import SwiftUI
import Auth

enum RootTab: Hashable {
    case home, explore, my, profile
}

struct RootView: View {
    var authVM: AuthViewModel
    @State private var tab: RootTab = .home
    @State private var detail: Item? = nil
    @State private var reportType: ItemStatus? = nil
    @State private var publicProfileId: UUID? = nil
    @State private var showNotifications = false
    @State private var itemsVM = ItemsViewModel()
    @State private var notifVM = NotificationsViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .padding(.bottom, 56)
            customTabBar
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
        .task {
            itemsVM.setUser(authVM.user?.id)
            await itemsVM.fetch()
            if let uid = authVM.user?.id {
                await notifVM.fetch(userId: uid)
            }
        }
        .sheet(item: $detail) { item in
            ItemDetailScreen(
                item: item,
                currentUserId: authVM.user?.id,
                onBack: { detail = nil },
                onItemUpdated: { Task { await itemsVM.fetch() } }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsScreen(
                notifVM: notifVM,
                currentUserId: authVM.user?.id,
                onItem: { itemId in
                    showNotifications = false
                    detail = itemsVM.items.first { $0.id == itemId }
                },
                onBack: { showNotifications = false }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(item: Binding(
            get: { publicProfileId.map { ProfileSheetID(id: $0) } },
            set: { publicProfileId = $0?.id }
        )) { wrapper in
            PublicProfileScreen(
                userId: wrapper.id,
                onBack: { publicProfileId = nil },
                onItem: { detail = $0 }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(item: Binding(
            get: { reportType.map { ReportSheetType(status: $0) } },
            set: { reportType = $0?.status }
        )) { wrapper in
            ReportScreen(type: wrapper.status, onClose: { reportType = nil }, onSubmitted: {
                Task { await itemsVM.fetch() }
            })
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .home:    HomeScreen(itemsVM: itemsVM, notifVM: notifVM, onItem: { detail = $0 }, onReport: { reportType = $0 }, onReporterTap: { publicProfileId = $0 }, onNotificationsTap: { showNotifications = true })
        case .explore: ExploreScreen(itemsVM: itemsVM, onItem: { detail = $0 })
        case .my:      MyItemsScreen(itemsVM: itemsVM, onItem: { detail = $0 }, onReport: { reportType = .lost })
        case .profile: ProfileScreen(authVM: authVM, itemsVM: itemsVM, onItem: { detail = $0 }, onSeeAll: { tab = .my })
        }
    }

    private var customTabBar: some View {
        ZStack {
            HStack(spacing: 0) {
                tabButton(.home,    label: "Home",     systemName: "house.fill")
                tabButton(.explore, label: "Explore",  systemName: "map.fill")
                Color.clear.frame(maxWidth: .infinity)
                tabButton(.my,      label: "My Items", systemName: "tray.full.fill")
                tabButton(.profile, label: "Profile",  systemName: "person.fill")
            }
            .frame(height: 56)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1)
            }

            Button {
                reportType = .found
            } label: {
                ZStack {
                    Circle()
                        .fill(KUTheme.Palette.neutral900)
                        .frame(width: 58, height: 58)
                        .overlay(Circle().stroke(.white, lineWidth: 4))
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(KUPressStyle())
            .offset(y: -18)
        }
        .frame(maxWidth: .infinity)
    }

    private func tabButton(_ id: RootTab, label: String, systemName: String) -> some View {
        Button { tab = id } label: {
            VStack(spacing: 3) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .semibold))
                Text(label)
                    .font(Font.Sarabun.medium(10))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(tab == id ? KUTheme.Palette.primary700 : KUTheme.Palette.neutral400)
        }
        .buttonStyle(.plain)
    }
}

private struct ReportSheetType: Identifiable {
    let status: ItemStatus
    var id: String { status.rawValue }
}

private struct ProfileSheetID: Identifiable {
    let id: UUID
}

#Preview { RootView(authVM: AuthViewModel()) }
