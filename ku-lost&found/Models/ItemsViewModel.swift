import Foundation
import Observation
import Supabase

@Observable
final class ItemsViewModel {
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?

    private var userId: UUID?

    func setUser(_ id: UUID?) {
        userId = id
    }

    var myItems: [Item] {
        guard let userId else { return [] }
        return items.filter { $0.reporterId == userId }
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
