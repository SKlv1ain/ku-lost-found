import Foundation
import Observation
import Supabase

@Observable
final class ItemsViewModel {
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?
    var photoURLs: [UUID: [URL]] = [:]
    var reporterNames: [UUID: String] = [:]

    private var userId: UUID?

    func setUser(_ id: UUID?) {
        userId = id
    }

    var myItems: [Item] {
        guard let userId else { return [] }
        return items.filter { $0.reporterId == userId }
    }

    func firstPhotoURL(for itemId: UUID) -> URL? {
        photoURLs[itemId]?.first
    }

    func reporterName(for item: Item) -> String? {
        guard let rid = item.reporterId else { return nil }
        return reporterNames[rid]
    }

    func fetch() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result: [Item] = try await supabase
                .from("items")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            items = result
            await fetchPhotos(for: result)
            await fetchReporterNames(for: result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMyItems() async {
        guard let userId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result: [Item] = try await supabase
                .from("items")
                .select()
                .eq("reporter_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            items = result
            await fetchPhotos(for: result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private struct ItemPhoto: Decodable {
        let item_id: UUID
        let storage_path: String
    }

    private struct ReporterProfile: Decodable {
        let id: UUID
        let fullName: String
        enum CodingKeys: String, CodingKey {
            case id, fullName = "full_name"
        }
    }

    private func fetchReporterNames(for items: [Item]) async {
        let ids = Set(items.compactMap { $0.reporterId }).map { $0.uuidString }
        guard !ids.isEmpty else { return }
        do {
            let profiles: [ReporterProfile] = try await supabase
                .from("profiles")
                .select("id, full_name")
                .in("id", values: ids)
                .execute()
                .value
            var map: [UUID: String] = [:]
            for p in profiles { map[p.id] = p.fullName }
            reporterNames.merge(map) { _, new in new }
        } catch {}
    }

    private func fetchPhotos(for items: [Item]) async {
        let ids = items.map { $0.id.uuidString }
        guard !ids.isEmpty else { return }

        do {
            let photos: [ItemPhoto] = try await supabase
                .from("item_photos")
                .select("item_id, storage_path")
                .in("item_id", values: ids)
                .execute()
                .value

            var map: [UUID: [URL]] = [:]
            for photo in photos {
                if let url = try? supabase.storage
                    .from("item-photos")
                    .getPublicURL(path: photo.storage_path) {
                    map[photo.item_id, default: []].append(url)
                }
            }
            photoURLs.merge(map) { _, new in new }
        } catch {
            // Non-fatal
        }
    }
}
