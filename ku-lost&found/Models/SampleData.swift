import Foundation
import CoreLocation

enum SampleData {
    static let kuCenter = CLLocationCoordinate2D(latitude: 13.8466, longitude: 100.5696)

    static let categories: [ItemCategory] = [.all, .electronics, .clothing, .idCard, .keys, .bag, .books, .other]

    static let items: [Item] = [
        .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
              reporterId: nil, emoji: "🎒", title: "Blue backpack",
              locationName: "Engineering Building 4", status: .found,
              category: .bag, description: "Found near the lobby of Engineering Building 4.",
              lat: 13.8460, lng: 100.5685,
              occurredAt: Date().addingTimeInterval(-7200), createdAt: Date().addingTimeInterval(-7200)),

        .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
              reporterId: nil, emoji: "🔑", title: "Key ring (3 keys)",
              locationName: "Cafeteria area", status: .lost,
              category: .keys, description: "Lost my key ring with three silver keys.",
              lat: 13.8472, lng: 100.5705,
              occurredAt: Date().addingTimeInterval(-86400), createdAt: Date().addingTimeInterval(-86400)),

        .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
              reporterId: nil, emoji: "💳", title: "Student ID card",
              locationName: "Main security office", status: .claimed,
              category: .idCard, description: "Student ID has been claimed.",
              lat: 13.8458, lng: 100.5712,
              occurredAt: Date().addingTimeInterval(-259200), createdAt: Date().addingTimeInterval(-259200)),

        .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
              reporterId: nil, emoji: "🎧", title: "Wireless earbuds",
              locationName: "KU Library, 2nd floor", status: .found,
              category: .electronics, description: "White wireless earbuds in a small charging case.",
              lat: 13.8482, lng: 100.5700,
              occurredAt: Date().addingTimeInterval(-18000), createdAt: Date().addingTimeInterval(-18000)),

        .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
              reporterId: nil, emoji: "📱", title: "iPhone (black case)",
              locationName: "Near Auditorium", status: .lost,
              category: .electronics, description: "Lost an iPhone with a plain black silicone case.",
              lat: 13.8447, lng: 100.5690,
              occurredAt: Date().addingTimeInterval(-86400), createdAt: Date().addingTimeInterval(-86400)),

        .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
              reporterId: nil, emoji: "📓", title: "Calculus textbook",
              locationName: "Science Building", status: .found,
              category: .books, description: "Calculus textbook with annotations.",
              lat: 13.8478, lng: 100.5680,
              occurredAt: Date().addingTimeInterval(-21600), createdAt: Date().addingTimeInterval(-21600)),

        .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
              reporterId: nil, emoji: "🧥", title: "Black KU jacket",
              locationName: "Sports Complex", status: .lost,
              category: .clothing, description: "Black KU varsity jacket, size M.",
              lat: 13.8488, lng: 100.5720,
              occurredAt: Date().addingTimeInterval(-172800), createdAt: Date().addingTimeInterval(-172800)),
    ]
}
