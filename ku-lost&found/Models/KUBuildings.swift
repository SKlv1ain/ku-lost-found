import CoreLocation

// Approximate KU Bang Khen campus bounds — used to filter search results to campus only.
enum KUCampus {
    static let center = CLLocationCoordinate2D(latitude: 13.8466, longitude: 100.5696)
    static let span   = (latDelta: 0.030, lngDelta: 0.030)

    static func distanceMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let dlat = (a.latitude  - b.latitude)  * 111_000
        let dlng = (a.longitude - b.longitude) * 111_000 * cos(a.latitude * .pi / 180)
        return sqrt(dlat * dlat + dlng * dlng)
    }
}
