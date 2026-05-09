import Foundation
import CoreLocation

enum ItemStatus: String, CaseIterable, Codable {
    case found, lost, claimed, expired

    var label: String {
        switch self {
        case .found: return "Found"
        case .lost: return "Lost"
        case .claimed: return "Claimed"
        case .expired: return "Expired"
        }
    }
}

enum ItemCategory: String, CaseIterable, Codable {
    case all = "All"
    case electronics = "Electronics"
    case clothing = "Clothing"
    case idCard = "ID / Card"
    case keys = "Keys"
    case bag = "Bag"
    case books = "Books"
    case other = "Other"
}

struct Item: Identifiable, Hashable {
    let id: Int
    let emoji: String
    let title: String
    let location: String
    let status: ItemStatus
    let time: String
    let category: ItemCategory
    let coordinate: CLLocationCoordinate2D?
    let description: String

    static func == (lhs: Item, rhs: Item) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
