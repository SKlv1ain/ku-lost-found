import SwiftUI
import Supabase

private struct UserProfile: Decodable, Sendable {
    let faculty: String?
    let year: Int?
    let avatarURL: String?
    let phone: String?
    let instagram: String?
    let lineId: String?
    enum CodingKeys: String, CodingKey {
        case faculty, year
        case avatarURL  = "avatar_url"
        case phone
        case instagram
        case lineId     = "line_id"
    }
}

private struct ProfileStats: Decodable, Sendable {
    let reportedCount: Int
    let returnedCount: Int
    let helpedCount: Int
    enum CodingKeys: String, CodingKey {
        case reportedCount = "reported_count"
        case returnedCount = "returned_count"
        case helpedCount   = "helped_count"
    }
}

struct ProfileScreen: View {
    var authVM: AuthViewModel
    var itemsVM: ItemsViewModel
    var onItem: (Item) -> Void
    var onSeeAll: () -> Void

    @State private var faculty: String? = nil
    @State private var year: Int? = nil
    @State private var avatarURL: String? = nil
    @State private var phone: String? = nil
    @State private var instagram: String? = nil
    @State private var lineId: String? = nil
    @State private var stats = ProfileStats(reportedCount: 0, returnedCount: 0, helpedCount: 0)

    // Edit sheet
    @State private var showEditSheet = false
    @State private var editFaculty   = ""
    @State private var editYear      = 1
    @State private var editPhone     = ""
    @State private var editInstagram = ""
    @State private var editLineId    = ""
    @State private var isSaving      = false
    @State private var saveError: String? = nil

    private var displayName: String {
        if let meta = authVM.user?.userMetadata,
           let name = meta["full_name"]?.stringValue, !name.isEmpty { return name }
        return authVM.user?.email?.components(separatedBy: "@").first ?? "User"
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    statRow
                    section(title: "My reports", action: "See all", onAction: onSeeAll) {
                        VStack(spacing: 10) {
                            ForEach(itemsVM.myItems.prefix(2)) { item in
                                ItemCard(item: item, photoURL: itemsVM.firstPhotoURL(for: item.id)) { onItem(item) }
                            }
                            if itemsVM.myItems.isEmpty {
                                Text("No reports yet.")
                                    .font(Font.Sarabun.regular(14))
                                    .foregroundStyle(KUTheme.Palette.neutral400)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    settingsList
                    signOutButton
                }
                .padding(16)
                .padding(.bottom, 80)
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
        .task { await loadProfile() }
        .sheet(isPresented: $showEditSheet) { editSheet }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text("My Profile")
                .font(Font.Sarabun.semibold(17))
                .foregroundStyle(KUTheme.Palette.neutral900)
            HStack {
                Spacer()
                Button("Edit") {
                    editFaculty   = faculty   ?? ""
                    editYear      = year      ?? 1
                    editPhone     = phone     ?? ""
                    editInstagram = instagram ?? ""
                    editLineId    = lineId    ?? ""
                    saveError     = nil
                    showEditSheet = true
                }
                .font(Font.Sarabun.medium(15))
                .foregroundStyle(KUTheme.Palette.primary700)
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

    private var profileHeader: some View {
        VStack(spacing: 10) {
            avatarView
                .frame(width: 96, height: 96)
                .overlay(Circle().stroke(KUTheme.Palette.neutral200, lineWidth: 1))

            VStack(spacing: 4) {
                Text(displayName)
                    .font(Font.Sarabun.bold(20))
                    .foregroundStyle(KUTheme.Palette.neutral900)
                Text(authVM.user?.email ?? "—")
                    .font(Font.Sarabun.regular(13))
                    .foregroundStyle(KUTheme.Palette.neutral600)
            }

            let tags = buildTags()
            if !tags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag($0) }
                }
            }

            // Contact row
            let contacts = buildContacts()
            if !contacts.isEmpty {
                HStack(spacing: 16) {
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
    private var avatarView: some View {
        if let urlString = avatarURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill().clipShape(Circle())
                } else {
                    fallbackAvatar
                }
            }
        } else {
            fallbackAvatar
        }
    }

    private var fallbackAvatar: some View {
        ZStack {
            Circle().fill(KUTheme.Palette.neutral900)
            Text("👤").font(.system(size: 48))
        }
    }

    private func buildTags() -> [String] {
        var tags: [String] = []
        if let f = faculty, !f.isEmpty { tags.append(f) }
        if let y = year { tags.append("Year \(y)") }
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

    private func buildContacts() -> [ContactInfo] {
        var list: [ContactInfo] = []
        if let p = phone,     !p.isEmpty { list.append(.init(icon: "phone.fill",    value: p, color: KUTheme.Palette.success)) }
        if let ig = instagram, !ig.isEmpty { list.append(.init(icon: "camera.fill", value: "@\(ig)", color: Color(hex: 0xE1306C))) }
        if let l = lineId,    !l.isEmpty { list.append(.init(icon: "message.fill",  value: l, color: Color(hex: 0x06C755))) }
        return list
    }

    private func contactChip(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(Font.Sarabun.medium(12))
                .foregroundStyle(KUTheme.Palette.neutral700)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(KUTheme.Palette.neutral100, in: Capsule())
        .overlay(Capsule().stroke(KUTheme.Palette.neutral200, lineWidth: 1))
    }

    // MARK: - Stats

    private var statRow: some View {
        HStack(spacing: 10) {
            statCard(value: "\(stats.reportedCount)", label: "Reported", icon: "square.and.pencil",    color: KUTheme.Palette.primary700)
            statCard(value: "\(stats.returnedCount)", label: "Returned", icon: "checkmark.circle.fill", color: KUTheme.Palette.success)
            statCard(value: "\(stats.helpedCount)",   label: "Helped",   icon: "hands.clap.fill",       color: KUTheme.Palette.accent700)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(Font.Sarabun.bold(20))
                .foregroundStyle(KUTheme.Palette.neutral900)
            Text(label)
                .font(Font.Sarabun.regular(11))
                .foregroundStyle(KUTheme.Palette.neutral600)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(KUTheme.Palette.white,
                    in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
        )
    }

    // MARK: - Section

    @ViewBuilder
    private func section<C: View>(title: String, action: String? = nil, onAction: (() -> Void)? = nil, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: title, action: action) { onAction?() }
            content()
        }
    }

    // MARK: - Settings

    private var settingsList: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "bell.fill",               label: "Notifications")
            divider
            settingsRow(icon: "lock.fill",               label: "Privacy")
            divider
            settingsRow(icon: "questionmark.circle.fill", label: "Help & Support")
            divider
            settingsRow(icon: "info.circle.fill",         label: "About")
        }
        .background(KUTheme.Palette.white,
                    in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1).padding(.leading, 48)
    }

    private func settingsRow(icon: String, label: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KUTheme.Palette.primary700)
                    .frame(width: 24)
                Text(label)
                    .font(Font.Sarabun.medium(15))
                    .foregroundStyle(KUTheme.Palette.neutral900)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KUTheme.Palette.neutral300)
            }
            .padding(14)
        }
        .buttonStyle(KUTappableStyle())
    }

    // MARK: - Sign out

    private var signOutButton: some View {
        Button(action: { Task { await authVM.signOut() } }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.square")
                Text("Sign out").font(Font.Sarabun.semibold(15))
            }
            .foregroundStyle(KUTheme.Palette.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KUTheme.Palette.dangerBg,
                        in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
        }
        .buttonStyle(KUTappableStyle())
    }

    // MARK: - Edit sheet

    private var editSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    editSectionLabel("Academic")

                    editField(label: "Faculty", placeholder: "e.g. Engineering", text: $editFaculty, keyboard: .default, icon: "building.columns.fill")

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Year", systemImage: "graduationcap.fill")
                            .font(Font.Sarabun.medium(14))
                            .foregroundStyle(KUTheme.Palette.neutral600)
                        Picker("Year", selection: $editYear) {
                            ForEach(1...8, id: \.self) { y in
                                Text("Year \(y)").tag(y)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KUTheme.Palette.white,
                                    in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
                        )
                    }

                    editSectionLabel("Contact")

                    editField(label: "Phone number", placeholder: "e.g. 0812345678", text: $editPhone, keyboard: .phonePad, icon: "phone.fill")
                    editField(label: "Instagram", placeholder: "username (without @)", text: $editInstagram, keyboard: .twitter, icon: "camera.fill")
                    editField(label: "LINE ID", placeholder: "your LINE ID", text: $editLineId, keyboard: .default, icon: "message.fill")

                    if let err = saveError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 13))
                            Text(err).font(Font.Sarabun.medium(13))
                        }
                        .foregroundStyle(KUTheme.Palette.accent500)
                        .padding(12)
                        .background(KUTheme.Palette.accent50,
                                    in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                    }

                    PrimaryButton(
                        label: isSaving ? "Saving…" : "Save changes",
                        icon: "checkmark",
                        color: KUTheme.Palette.primary700
                    ) {
                        Task { await saveProfile() }
                    }
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.7 : 1)
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .background(KUTheme.Palette.neutral100.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditSheet = false }
                        .foregroundStyle(KUTheme.Palette.primary700)
                }
            }
        }
    }

    private func editSectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(Font.Sarabun.semibold(11))
            .foregroundStyle(KUTheme.Palette.neutral400)
            .padding(.top, 4)
    }

    private func editField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(Font.Sarabun.medium(14))
                .foregroundStyle(KUTheme.Palette.neutral600)
            TextField(placeholder, text: text)
                .font(Font.Sarabun.regular(15))
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(KUTheme.Palette.white,
                            in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                        .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
                )
        }
    }

    // MARK: - Data loading

    private func loadProfile() async {
        guard let userId = authVM.user?.id else { return }
        let idString = userId.uuidString.lowercased()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                guard let profile = try? await supabase
                    .from("profiles")
                    .select("faculty, year, avatar_url, phone, instagram, line_id")
                    .eq("id", value: idString)
                    .single()
                    .execute()
                    .value as UserProfile
                else { return }
                await MainActor.run {
                    faculty   = profile.faculty
                    year      = profile.year
                    avatarURL = profile.avatarURL
                    phone     = profile.phone
                    instagram = profile.instagram
                    lineId    = profile.lineId
                }
            }
            group.addTask {
                guard let s = try? await supabase
                    .from("profile_stats")
                    .select("reported_count, returned_count, helped_count")
                    .eq("id", value: idString)
                    .single()
                    .execute()
                    .value as ProfileStats
                else { return }
                await MainActor.run { stats = s }
            }
        }
    }

    // MARK: - Save profile

    private func saveProfile() async {
        guard let userId = authVM.user?.id else { return }
        isSaving  = true
        saveError = nil
        defer { isSaving = false }

        struct ProfileUpdate: Encodable {
            let faculty:   String?
            let year:      Int
            let phone:     String?
            let instagram: String?
            let line_id:   String?
        }

        func nilIfEmpty(_ s: String) -> String? {
            s.trimmingCharacters(in: .whitespaces).isEmpty ? nil : s.trimmingCharacters(in: .whitespaces)
        }

        let payload = ProfileUpdate(
            faculty:   nilIfEmpty(editFaculty),
            year:      editYear,
            phone:     nilIfEmpty(editPhone),
            instagram: nilIfEmpty(editInstagram),
            line_id:   nilIfEmpty(editLineId)
        )

        do {
            try await supabase
                .from("profiles")
                .update(payload)
                .eq("id", value: userId.uuidString.lowercased())
                .execute()
            await MainActor.run {
                faculty   = payload.faculty
                year      = payload.year
                phone     = payload.phone
                instagram = payload.instagram
                lineId    = payload.line_id
                showEditSheet = false
            }
        } catch {
            await MainActor.run { saveError = error.localizedDescription }
        }
    }
}

#Preview { ProfileScreen(authVM: AuthViewModel(), itemsVM: ItemsViewModel(), onItem: { _ in }, onSeeAll: {}) }
