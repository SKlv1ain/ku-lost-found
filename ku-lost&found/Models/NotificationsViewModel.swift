import Foundation
import Observation
import Supabase

enum NotificationKind: String, Decodable {
    case claimSubmitted = "claim_submitted"
    case claimApproved  = "claim_approved"
    case claimRejected  = "claim_rejected"
    case sightingAdded  = "sighting_added"
}

struct NotifItem: Decodable, Sendable {
    let title: String
    let emoji: String
}

struct NotifActor: Decodable, Sendable {
    let fullName: String
    enum CodingKeys: String, CodingKey { case fullName = "full_name" }
}

struct AppNotification: Identifiable, Decodable {
    let id: UUID
    let kind: NotificationKind
    let itemId: UUID?
    let actorId: UUID?
    var readAt: Date?
    let createdAt: Date
    let item: NotifItem?
    let actor: NotifActor?

    var isUnread: Bool { readAt == nil }

    var timeAgo: String {
        let s = Date().timeIntervalSince(createdAt)
        if s < 60     { return "Just now" }
        if s < 3600   { return "\(Int(s / 60))m ago" }
        if s < 86400  { return "\(Int(s / 3600))h ago" }
        let d = Int(s / 86400)
        if d == 1 { return "Yesterday" }
        if d < 7  { return "\(d) days ago" }
        return "\(d / 7)w ago"
    }

    enum CodingKeys: String, CodingKey {
        case id, kind
        case itemId   = "item_id"
        case actorId  = "actor_id"
        case readAt   = "read_at"
        case createdAt = "created_at"
        case item = "items"
        case actor
    }
}

@Observable
final class NotificationsViewModel {
    var notifications: [AppNotification] = []
    var isLoading = false

    var unreadCount: Int { notifications.filter { $0.isUnread }.count }

    func fetch(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result: [AppNotification] = try await supabase
                .from("notifications")
                .select("*, items(title, emoji), actor:profiles!notifications_actor_id_fkey(full_name)")
                .eq("user_id", value: userId.uuidString.lowercased())
                .order("created_at", ascending: false)
                .execute()
                .value
            notifications = result
        } catch {}
    }

    func markRead(_ notif: AppNotification) async {
        guard notif.isUnread else { return }
        let now = Date()
        do {
            try await supabase
                .from("notifications")
                .update(["read_at": ISO8601DateFormatter().string(from: now)])
                .eq("id", value: notif.id.uuidString.lowercased())
                .execute()
            if let idx = notifications.firstIndex(where: { $0.id == notif.id }) {
                notifications[idx].readAt = now
            }
        } catch {}
    }

    func markAllRead(userId: UUID) async {
        let now = Date()
        do {
            try await supabase
                .from("notifications")
                .update(["read_at": ISO8601DateFormatter().string(from: now)])
                .eq("user_id", value: userId.uuidString.lowercased())
                .execute()
            for idx in notifications.indices {
                notifications[idx].readAt = now
            }
        } catch {}
    }

    func delete(_ id: UUID) async {
        do {
            try await supabase
                .from("notifications")
                .delete()
                .eq("id", value: id.uuidString.lowercased())
                .execute()
            notifications.removeAll { $0.id == id }
        } catch {}
    }
}
