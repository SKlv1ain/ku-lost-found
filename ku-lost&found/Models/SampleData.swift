import Foundation
import CoreLocation

// Faithful port of SAMPLE_ITEMS from HomeScreen.jsx with KU Bang Khen coordinates.
enum SampleData {
    static let kuCenter = CLLocationCoordinate2D(latitude: 13.8466, longitude: 100.5696)

    static let items: [Item] = [
        .init(id: 1, emoji: "🎒", title: "Blue backpack",
              location: "Engineering Building 4", status: .found, time: "2h ago",
              category: .bag,
              coordinate: .init(latitude: 13.8460, longitude: 100.5685),
              description: "Found near the lobby of Engineering Building 4. Looks like a student backpack with a laptop sleeve."),

        .init(id: 2, emoji: "🔑", title: "Key ring (3 keys)",
              location: "Cafeteria area", status: .lost, time: "Yesterday",
              category: .keys,
              coordinate: .init(latitude: 13.8472, longitude: 100.5705),
              description: "I lost my key ring with three silver keys and a small KU lanyard around the cafeteria yesterday afternoon."),

        .init(id: 3, emoji: "💳", title: "Student ID card",
              location: "Main security office", status: .claimed, time: "3 days ago",
              category: .idCard,
              coordinate: .init(latitude: 13.8458, longitude: 100.5712),
              description: "Student ID has been claimed and returned to its owner."),

        .init(id: 4, emoji: "🎧", title: "Wireless earbuds",
              location: "KU Library, 2nd floor", status: .found, time: "5h ago",
              category: .electronics,
              coordinate: .init(latitude: 13.8482, longitude: 100.5700),
              description: "White wireless earbuds in a small charging case. Found on the 2nd floor reading area of the KU Library."),

        .init(id: 5, emoji: "📱", title: "iPhone (black case)",
              location: "Near Auditorium", status: .lost, time: "1 day ago",
              category: .electronics,
              coordinate: .init(latitude: 13.8447, longitude: 100.5690),
              description: "Lost an iPhone with a plain black silicone case yesterday near the main auditorium. Lock screen shows a campus photo."),

        .init(id: 6, emoji: "📓", title: "Calculus textbook",
              location: "Science Building", status: .found, time: "6h ago",
              category: .books,
              coordinate: .init(latitude: 13.8478, longitude: 100.5680),
              description: "Calculus textbook with annotations and a yellow KU sticker. Found on a desk in the Science Building."),

        .init(id: 7, emoji: "🧥", title: "Black KU jacket",
              location: "Sports Complex", status: .lost, time: "2 days ago",
              category: .clothing,
              coordinate: .init(latitude: 13.8488, longitude: 100.5720),
              description: "Black KU varsity jacket, size M. Last seen at the sports complex changing room two days ago."),
    ]

    static let categories: [ItemCategory] = [.all, .electronics, .clothing, .idCard, .keys, .bag, .books, .other]
}
