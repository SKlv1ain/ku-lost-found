import SwiftUI

struct NotificationsScreen: View {
    var notifVM: NotificationsViewModel
    var currentUserId: UUID?
    var onItem: ((UUID) -> Void)? = nil
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            navBar
            if notifVM.isLoading && notifVM.notifications.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if notifVM.notifications.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(notifVM.notifications) { notif in
                            notifRow(notif)
                            if notif.id != notifVM.notifications.last?.id {
                                Rectangle()
                                    .fill(KUTheme.Palette.neutral200)
                                    .frame(height: 1)
                                    .padding(.leading, 68)
                            }
                        }
                    }
                    .background(KUTheme.Palette.white,
                                in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                            .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
                    )
                    .padding(16)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    if let uid = currentUserId { await notifVM.fetch(userId: uid) }
                }
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
        .task {
            if let uid = currentUserId { await notifVM.fetch(userId: uid) }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text("Notifications")
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
                if notifVM.unreadCount > 0 {
                    Button("Mark all read") {
                        Task {
                            if let uid = currentUserId { await notifVM.markAllRead(userId: uid) }
                        }
                    }
                    .font(Font.Sarabun.medium(14))
                    .foregroundStyle(KUTheme.Palette.primary700)
                }
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

    // MARK: - Row

    private func notifRow(_ notif: AppNotification) -> some View {
        Button {
            Task { await notifVM.markRead(notif) }
            if let itemId = notif.itemId { onItem?(itemId) }
        } label: {
            HStack(spacing: 12) {
                // Unread dot
                Circle()
                    .fill(notif.isUnread ? KUTheme.Palette.primary700 : Color.clear)
                    .frame(width: 8, height: 8)

                // Icon
                ZStack {
                    Circle().fill(palette(notif.kind).bg)
                    Image(systemName: palette(notif.kind).icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(palette(notif.kind).fg)
                }
                .frame(width: 40, height: 40)

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(titleText(notif))
                        .font(notif.isUnread ? Font.Sarabun.semibold(14) : Font.Sarabun.regular(14))
                        .foregroundStyle(KUTheme.Palette.neutral900)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let item = notif.item {
                        Text("\(item.emoji) \(item.title)")
                            .font(Font.Sarabun.regular(12))
                            .foregroundStyle(KUTheme.Palette.neutral600)
                            .lineLimit(1)
                    }
                    Text(notif.timeAgo)
                        .font(Font.Sarabun.regular(11))
                        .foregroundStyle(KUTheme.Palette.neutral400)
                        .padding(.top, 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if notif.itemId != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(KUTheme.Palette.neutral300)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(notif.isUnread ? KUTheme.Palette.primary50 : Color.clear)
        }
        .buttonStyle(KUTappableStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task { await notifVM.delete(notif.id) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Kind palette

    private struct KindPalette { let icon: String; let fg: Color; let bg: Color }

    private func palette(_ kind: NotificationKind) -> KindPalette {
        switch kind {
        case .claimSubmitted:
            return .init(icon: "person.fill.badge.plus",  fg: KUTheme.Palette.lostText,   bg: KUTheme.Palette.warningBg)
        case .claimApproved:
            return .init(icon: "checkmark.circle.fill",   fg: KUTheme.Palette.success,    bg: KUTheme.Palette.successBg)
        case .claimRejected:
            return .init(icon: "xmark.circle.fill",       fg: KUTheme.Palette.danger,     bg: KUTheme.Palette.dangerBg)
        case .sightingAdded:
            return .init(icon: "eye.fill",                fg: KUTheme.Palette.primary700, bg: KUTheme.Palette.primary50)
        }
    }

    // MARK: - Title text

    private func titleText(_ notif: AppNotification) -> String {
        let item  = notif.item?.title  ?? "an item"
        let actor = notif.actor?.fullName ?? "Someone"
        switch notif.kind {
        case .claimSubmitted: return "\(actor) claimed your \"\(item)\""
        case .claimApproved:  return "Your claim on \"\(item)\" was approved ✓"
        case .claimRejected:  return "Your claim on \"\(item)\" was not approved"
        case .sightingAdded:  return "\(actor) spotted \"\(item)\""
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(KUTheme.Palette.neutral300)
            Text("No notifications yet")
                .font(Font.Sarabun.semibold(17))
                .foregroundStyle(KUTheme.Palette.neutral600)
            Text("You'll be notified when someone claims your item or when your claim gets reviewed.")
                .font(Font.Sarabun.regular(13))
                .foregroundStyle(KUTheme.Palette.neutral400)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
