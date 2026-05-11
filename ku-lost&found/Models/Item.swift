import Foundation
import CoreLocation

enum ItemStatus: String, CaseIterable, Codable {
    case found, lost, claimed, expired, returned

    var label: String {
        switch self {
        case .found:    return "Found"
        case .lost:     return "Lost"
        case .claimed:  return "Claimed"
        case .expired:  return "Expired"
        case .returned: return "Returned"
        }
    }
}

enum ItemCategory: String, CaseIterable, Codable {
    case all
    case electronics
    case clothing
    case idCard = "id_card"
    case keys
    case bag
    case books
    case other

    var label: String {
        switch self {
        case .all: return "All"
        case .electronics: return "Electronics"
        case .clothing: return "Clothing"
        case .idCard: return "ID / Card"
        case .keys: return "Keys"
        case .bag: return "Bag"
        case .books: return "Books"
        case .other: return "Other"
        }
    }
}

struct Item: Identifiable, Hashable, Codable {
    let id: UUID
    let reporterId: UUID?
    let emoji: String
    let title: String
    let locationName: String
    let status: ItemStatus
    let category: ItemCategory
    let description: String
    let lat: Double?
    let lng: Double?
    let occurredAt: Date?
    let createdAt: Date?
    let hintQuestion: String?
    let returnedAt: Date?

    var location: String { locationName }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var time: String {
        guard let date = occurredAt ?? createdAt else { return "" }
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 { return "Just now" }
        if interval < 3600 {
            let m = Int(interval / 60)
            return "\(m)m ago"
        }
        if interval < 86400 {
            let h = Int(interval / 3600)
            return "\(h)h ago"
        }
        if interval < 172800 { return "Yesterday" }
        let d = Int(interval / 86400)
        if d < 7 { return "\(d) days ago" }
        let w = d / 7
        return "\(w) week\(w == 1 ? "" : "s") ago"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case reporterId = "reporter_id"
        case emoji, title
        case locationName = "location_name"
        case status, category, description
        case lat, lng
        case occurredAt    = "occurred_at"
        case createdAt     = "created_at"
        case hintQuestion  = "hint_question"
        case returnedAt    = "returned_at"
    }

    static func == (lhs: Item, rhs: Item) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
