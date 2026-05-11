import SwiftUI
import Supabase

private struct PublicProfile: Decodable, Sendable {
    let fullName: String
    let avatarURL: String?
    let faculty: String?
    let year: Int?
    let phone: String?
    let instagram: String?
    let lineId: String?
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case faculty, year, phone, instagram
        case lineId = "line_id"
    }
}

private struct PublicStats: Decodable, Sendable {
    let reportedCount: Int
    
    let returnedCount: Int
    let helpedCount: Int
    enum CodingKeys: String, CodingKey {
        case reportedCount = "reported_count"
        case returnedCount = "returned_count"
        case helpedCount   = "helped_count"
    }
}

struct PublicProfileScreen: View {
    let userId: UUID
    let onBack: () -> Void
    var onItem: ((Item) -> Void)? = nil

    @State private var profile: PublicProfile? = nil
    @State private var stats: PublicStats? = nil
    @State private var items: [Item] = []
    @State private var photoURLs: [UUID: URL] = [:]
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            navBar
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let profile {
                ScrollView {
                    VStack(spacing: 18) {
                        profileHeader(profile)
                        if let stats { statRow(stats) }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                SectionHeader(title: "Reports (\(items.count))")
                                VStack(spacing: 10) {
                                    ForEach(items) { item in
                                        ItemCard(item: item, photoURL: photoURLs[item.id]) {
                                            onItem?(item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            } else {
                Spacer()
                Text("Profile not found.")
                    .font(Font.Sarabun.regular(15))
                    .foregroundStyle(KUTheme.Palette.neutral400)
                Spacer()
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
        .task { await loadAll() }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text("Profile")
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

    // MARK: - Profile header

    private func profileHeader(_ p: PublicProfile) -> some View {
        VStack(spacing: 10) {
            avatarView(url: p.avatarURL)
                .frame(width: 96, height: 96)
                .overlay(Circle().stroke(KUTheme.Palette.neutral200, lineWidth: 1))

            Text(p.fullName)
                .font(Font.Sarabun.bold(20))
                .foregroundStyle(KUTheme.Palette.neutral900)

            let tags = buildTags(p)
            if !tags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag($0) }
                }
            }

            let contacts = buildContacts(p)
            if !contacts.isEmpty {
                HStack(spacing: 14) {
                    ForEach(contacts, id: \.icon) { c in
                        contactChip(icon: c.icon, value: c.value, color: c.color)
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(KUTheme.Palette.white,
                    in: RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous)
                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func avatarView(url: String?) -> some View {
        if let urlString = url, let u = URL(string: urlString) {
            AsyncImage(url: u) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill().clipShape(Circle())
                } else { fallbackAvatar }
            }
        } else { fallbackAvatar }
    }

    private var fallbackAvatar: some View {
        ZStack {
            Circle().fill(KUTheme.Palette.neutral900)
            Text("👤").font(.system(size: 48))
        }
    }

    private func buildTags(_ p: PublicProfile) -> [String] {
        var tags: [String] = []
        if let f = p.faculty, !f.isEmpty { tags.append(f) }
        if let y = p.year { tags.append("Year \(y)") }
        return tags
    }

    private func tag(_ s: String) -> some View {
        Text(s)
            .font(Font.Sarabun.medium(12))
            .foregroundStyle(KUTheme.Palette.primary700)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(KUTheme.Palette.primary50, in: Capsule())
    }

    private struct ContactInfo { let icon: String; let value: String; let color: Color }

    private func buildContacts(_ p: PublicProfile) -> [ContactInfo] {
        var list: [ContactInfo] = []
        if let ph = p.phone,     !ph.isEmpty { list.append(.init(icon: "phone.fill",    value: ph,         color: KUTheme.Palette.success)) }
        if let ig = p.instagram, !ig.isEmpty { list.append(.init(icon: "camera.fill",   value: "@\(ig)",   color: Color(hex: 0xE1306C))) }
        if let l  = p.lineId,    !l.isEmpty  { list.append(.init(icon: "message.fill",  value: l,          color: Color(hex: 0x06C755))) }
        return list
    }

    private func contactChip(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(color)
            Text(value).font(Font.Sarabun.medium(12)).foregroundStyle(KUTheme.Palette.neutral700)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(KUTheme.Palette.neutral100, in: Capsule())
        .overlay(Capsule().stroke(KUTheme.Palette.neutral200, lineWidth: 1))
    }

    // MARK: - Stats

    private func statRow(_ s: PublicStats) -> some View {
        HStack(spacing: 10) {
            statCard(value: "\(s.reportedCount)", label: "Reported", icon: "square.and.pencil",     color: KUTheme.Palette.primary700)
            statCard(value: "\(s.returnedCount)", label: "Returned", icon: "checkmark.circle.fill",  color: KUTheme.Palette.success)
            statCard(value: "\(s.helpedCount)",   label: "Helped",   icon: "hands.clap.fill",        color: KUTheme.Palette.accent700)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(color)
            Text(value).font(Font.Sarabun.bold(20)).foregroundStyle(KUTheme.Palette.neutral900)
            Text(label).font(Font.Sarabun.regular(11)).foregroundStyle(KUTheme.Palette.neutral600)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous).stroke(KUTheme.Palette.neutral200, lineWidth: 1))
    }

    // MARK: - Data loading

    private func loadAll() async {
        let idString = userId.uuidString.lowercased()
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let p = try? await supabase
                    .from("profiles")
                    .select("full_name, avatar_url, faculty, year, phone, instagram, line_id")
                    .eq("id", value: idString)
                    .single()
                    .execute()
                    .value as PublicProfile
                await MainActor.run { profile = p }
            }
            group.addTask {
                let s = try? await supabase
                    .from("profile_stats")
                    .select("reported_count, returned_count, helped_count")
                    .eq("id", value: idString)
                    .single()
                    .execute()
                    .value as PublicStats
                await MainActor.run { stats = s }
            }
            group.addTask {
                let result = (try? await supabase
                    .from("items")
                    .select()
                    .eq("reporter_id", value: idString)
                    .order("created_at", ascending: false)
                    .execute()
                    .value) as [Item]? ?? []
                await MainActor.run { items = result }
                await loadPhotos(for: result)
            }
        }
        await MainActor.run { isLoading = false }
    }

    private func loadPhotos(for items: [Item]) async {
        struct ItemPhoto: Decodable { let item_id: UUID; let storage_path: String }
        let ids = items.map { $0.id.uuidString }
        guard !ids.isEmpty else { return }
        guard let photos = try? await supabase
            .from("item_photos")
            .select("item_id, storage_path")
            .in("item_id", values: ids)
            .execute()
            .value as [ItemPhoto]
        else { return }
        var map: [UUID: URL] = [:]
        for p in photos {
            if let url = try? supabase.storage.from("item-photos").getPublicURL(path: p.storage_path) {
                map[p.item_id] = url
            }
        }
        await MainActor.run { photoURLs = map }
    }
}
