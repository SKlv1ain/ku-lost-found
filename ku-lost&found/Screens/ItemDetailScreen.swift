import SwiftUI
import MapKit
import Supabase
import Auth

// MARK: - Claim model

struct Claim: Identifiable, Decodable {
    let id: UUID
    let itemId: UUID
    let claimerId: UUID
    let message: String?
    let state: ClaimState
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case claimerId = "claimer_id"
        case message
        case state
        case createdAt = "created_at"
    }
}

enum ClaimState: String, Decodable {
    case pending, approved, rejected, withdrawn
}

struct ContactProfile: Decodable, Sendable {
    let fullName: String
    let email: String?
    let phone: String?
    let instagram: String?
    let lineId: String?
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case email, phone, instagram
        case lineId = "line_id"
    }
}

// MARK: - ItemDetailScreen

struct ItemDetailScreen: View {
    let item: Item
    var currentUserId: UUID?
    let onBack: () -> Void
    var onItemUpdated: (() -> Void)? = nil

    @State private var photoURLs: [URL] = []
    @State private var currentPhoto = 0
    @State private var showFullscreen = false

    // Claim state
    @State private var myClaim: Claim? = nil
    @State private var incomingClaims: [Claim] = []
    @State private var showClaimSheet = false
    @State private var claimMessage = ""
    @State private var isBusy = false
    @State private var errorMessage: String?

    // Contact profiles (loaded after approval)
    @State private var reporterContact: ContactProfile? = nil
    @State private var approvedClaimerContact: ContactProfile? = nil

    private var isOwner: Bool {
        guard let uid = currentUserId else { return false }
        return item.reporterId == uid
    }

    private var isAlreadyClaimer: Bool { myClaim != nil }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            hero
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Text(item.title)
                            .font(Font.Sarabun.bold(22))
                            .foregroundStyle(KUTheme.Palette.neutral900)
                        StatusBadge(status: item.status)
                    }
                    metaCard

                    if let coord = item.coordinate {
                        locationMapPreview(coord)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this item")
                            .font(Font.Sarabun.semibold(15))
                            .foregroundStyle(KUTheme.Palette.neutral700)
                        if item.description.isEmpty {
                            Text("No description provided.")
                                .font(Font.Sarabun.regular(15))
                                .foregroundStyle(KUTheme.Palette.neutral400)
                                .italic()
                        } else {
                            Text(item.description)
                                .font(Font.Sarabun.regular(15))
                                .foregroundStyle(KUTheme.Palette.neutral700)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                    }

                    // CTA section
                    if isOwner {
                        ownerSection
                    } else {
                        claimerSection
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
        .task { await loadAll() }
        .sheet(isPresented: $showClaimSheet) { claimSheet }
        .fullScreenCover(isPresented: $showFullscreen) {
            PhotoFullscreen(urls: photoURLs, startIndex: currentPhoto) {
                showFullscreen = false
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text("Item Details")
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

    // MARK: - Hero

    private var hero: some View {
        ZStack {
            (item.status == .lost ? KUTheme.Palette.accent50 : KUTheme.Palette.primary50)

            if photoURLs.isEmpty {
                Text(item.emoji).font(.system(size: 100))
            } else {
                TabView(selection: $currentPhoto) {
                    ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, url in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                            case .failure:
                                VStack(spacing: 6) {
                                    Image(systemName: "photo").font(.system(size: 40))
                                    Text("Failed to load").font(Font.Sarabun.regular(12))
                                }
                                .foregroundStyle(KUTheme.Palette.neutral300)
                            default:
                                ProgressView()
                            }
                        }
                        .tag(index)
                        .contentShape(Rectangle())
                        .onTapGesture { showFullscreen = true }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            if !photoURLs.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        if photoURLs.count > 1 {
                            Text("\(currentPhoto + 1) / \(photoURLs.count)")
                                .font(Font.Sarabun.semibold(12))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.black.opacity(0.5), in: Capsule())
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .allowsHitTesting(false)
            }

            if photoURLs.count > 1 {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(photoURLs.indices, id: \.self) { i in
                            Circle()
                                .fill(i == currentPhoto ? Color.white : Color.white.opacity(0.4))
                                .frame(width: i == currentPhoto ? 8 : 6, height: i == currentPhoto ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: currentPhoto)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .frame(height: 260)
    }

    // MARK: - Meta card

    private var metaCard: some View {
        VStack(spacing: 0) {
            metaRow(icon: "mappin.and.ellipse", label: "Location", value: item.location.isEmpty ? "—" : item.location)
            divider
            metaRow(icon: "clock", label: "Reported", value: item.time)
            divider
            metaRow(icon: "number", label: "Item ID", value: "KU-\(item.id.uuidString.prefix(8).uppercased())", monospaced: true)
        }
        .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
        .kuShadow()
    }

    private var divider: some View {
        Rectangle().fill(KUTheme.Palette.neutral200).frame(height: 1).padding(.leading, 48)
    }

    private func metaRow(icon: String, label: String, value: String, monospaced: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(KUTheme.Palette.primary700)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(Font.Sarabun.regular(12)).foregroundStyle(KUTheme.Palette.neutral400)
                Text(value)
                    .font(monospaced ? .system(size: 14, design: .monospaced) : Font.Sarabun.medium(15))
                    .foregroundStyle(KUTheme.Palette.neutral900)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    // MARK: - Claimer section (non-owner)

    @ViewBuilder
    private var claimerSection: some View {
        VStack(spacing: 12) {
            if let err = errorMessage {
                errorBanner(err)
            }

            if item.status == .claimed {
                statusBanner(
                    icon: "checkmark.seal.fill",
                    text: "This item has already been claimed.",
                    color: KUTheme.Palette.info,
                    bg: KUTheme.Palette.infoBg
                )
            } else if let claim = myClaim {
                switch claim.state {
                case .pending:
                    VStack(spacing: 10) {
                        statusBanner(
                            icon: "clock.fill",
                            text: "Your claim is pending review.",
                            color: KUTheme.Palette.info,
                            bg: KUTheme.Palette.infoBg
                        )
                        if let msg = claim.message, !msg.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "text.bubble")
                                    .foregroundStyle(KUTheme.Palette.neutral400)
                                    .font(.system(size: 13))
                                Text(msg)
                                    .font(Font.Sarabun.regular(13))
                                    .foregroundStyle(KUTheme.Palette.neutral600)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .background(KUTheme.Palette.neutral100, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                        }
                        Button {
                            Task { await withdrawClaim(claim) }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle")
                                Text("Withdraw claim")
                                    .font(Font.Sarabun.semibold(14))
                            }
                            .foregroundStyle(KUTheme.Palette.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(KUTheme.Palette.dangerBg, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                        }
                        .buttonStyle(KUTappableStyle())
                        .disabled(isBusy)
                    }

                case .approved:
                    VStack(spacing: 10) {
                        statusBanner(
                            icon: "checkmark.circle.fill",
                            text: "Your claim was approved!",
                            color: KUTheme.Palette.success,
                            bg: KUTheme.Palette.successBg
                        )
                        if let contact = reporterContact {
                            contactCard(title: "Reporter's contact", profile: contact)
                        }
                    }

                case .rejected:
                    statusBanner(
                        icon: "xmark.circle.fill",
                        text: "Your claim was not approved.",
                        color: KUTheme.Palette.danger,
                        bg: KUTheme.Palette.dangerBg
                    )

                case .withdrawn:
                    PrimaryButton(
                        label: item.status == .lost ? "I found this item" : "This is mine",
                        icon: item.status == .lost ? "hand.raised.fill" : "hand.point.up.left.fill",
                        color: item.status == .lost ? KUTheme.Palette.accent700 : KUTheme.Palette.primary700
                    ) { showClaimSheet = true }
                }
            } else {
                PrimaryButton(
                    label: item.status == .lost ? "I found this item" : "This is mine",
                    icon: item.status == .lost ? "hand.raised.fill" : "hand.point.up.left.fill",
                    color: item.status == .lost ? KUTheme.Palette.accent700 : KUTheme.Palette.primary700
                ) { showClaimSheet = true }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Owner section (reporter of the item)

    @ViewBuilder
    private var ownerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let err = errorMessage {
                errorBanner(err)
            }

            // Show hint question reminder to owner
            if let hint = item.hintQuestion, !hint.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(KUTheme.Palette.primary700)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Your verification hint")
                            .font(Font.Sarabun.medium(11))
                            .foregroundStyle(KUTheme.Palette.neutral400)
                        Text(hint)
                            .font(Font.Sarabun.medium(13))
                            .foregroundStyle(KUTheme.Palette.neutral700)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KUTheme.Palette.primary50,
                            in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
            }

            if incomingClaims.isEmpty {
                statusBanner(
                    icon: "tray",
                    text: "No claims yet.",
                    color: KUTheme.Palette.neutral400,
                    bg: KUTheme.Palette.neutral100
                )
            } else {
                Text("Claims (\(incomingClaims.count))")
                    .font(Font.Sarabun.semibold(15))
                    .foregroundStyle(KUTheme.Palette.neutral700)

                ForEach(incomingClaims) { claim in
                    claimCard(claim)
                }

                // Approved claim: show claimer contact + Mark as returned
                if let contact = approvedClaimerContact {
                    contactCard(title: "Claimer's contact", profile: contact)

                    if item.status != .returned {
                        Button { Task { await markReturned() } } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Mark as returned")
                                    .font(Font.Sarabun.semibold(15))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(KUTheme.Palette.success,
                                        in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                        }
                        .buttonStyle(KUTappableStyle())
                        .disabled(isBusy)
                    } else {
                        statusBanner(
                            icon: "checkmark.seal.fill",
                            text: "Item successfully returned.",
                            color: KUTheme.Palette.success,
                            bg: KUTheme.Palette.successBg
                        )
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private func claimCard(_ claim: Claim) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(KUTheme.Palette.neutral200)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(KUTheme.Palette.neutral400)
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("KU-\(claim.claimerId.uuidString.prefix(8).uppercased())")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(KUTheme.Palette.neutral400)
                    if let date = claim.createdAt {
                        Text(date, style: .relative)
                            .font(Font.Sarabun.regular(11))
                            .foregroundStyle(KUTheme.Palette.neutral400)
                    }
                }
                Spacer()
                claimStateBadge(claim.state)
            }

            if let msg = claim.message, !msg.isEmpty {
                Text(msg)
                    .font(Font.Sarabun.regular(13))
                    .foregroundStyle(KUTheme.Palette.neutral700)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 40)
            }

            if claim.state == .pending {
                HStack(spacing: 10) {
                    Button { Task { await decideClaim(claim, approve: false) } } label: {
                        Text("Reject")
                            .font(Font.Sarabun.semibold(14))
                            .foregroundStyle(KUTheme.Palette.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(KUTheme.Palette.dangerBg, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                    }
                    .buttonStyle(KUTappableStyle())
                    .disabled(isBusy)

                    Button { Task { await decideClaim(claim, approve: true) } } label: {
                        Text("Approve")
                            .font(Font.Sarabun.semibold(14))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(KUTheme.Palette.success, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                    }
                    .buttonStyle(KUTappableStyle())
                    .disabled(isBusy)
                }
            }
        }
        .padding(14)
        .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func claimStateBadge(_ state: ClaimState) -> some View {
        let (label, color): (String, Color) = switch state {
        case .pending:  ("Pending",  KUTheme.Palette.info)
        case .approved: ("Approved", KUTheme.Palette.success)
        case .rejected: ("Rejected", KUTheme.Palette.danger)
        case .withdrawn:("Withdrawn",KUTheme.Palette.neutral400)
        }
        Text(label)
            .font(Font.Sarabun.semibold(11))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }

    // MARK: - Claim sheet

    private var claimSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add a message (optional)")
                        .font(Font.Sarabun.medium(14))
                        .foregroundStyle(KUTheme.Palette.neutral600)
                    TextEditor(text: $claimMessage)
                        .font(Font.Sarabun.regular(15))
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .frame(minHeight: 120)
                        .background(KUTheme.Palette.neutral100, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            if claimMessage.isEmpty {
                                Text("Describe why this is yours, or how you found it…")
                                    .font(Font.Sarabun.regular(14))
                                    .foregroundStyle(KUTheme.Palette.neutral400)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                if let err = errorMessage {
                    errorBanner(err)
                }

                Spacer()

                PrimaryButton(
                    label: isBusy ? "Submitting…" : (item.status == .lost ? "I found this item" : "This is mine"),
                    icon: "hand.point.up.left.fill",
                    color: item.status == .lost ? KUTheme.Palette.accent700 : KUTheme.Palette.primary700
                ) {
                    Task { await submitClaim() }
                }
                .disabled(isBusy)
                .opacity(isBusy ? 0.7 : 1)
            }
            .padding(20)
            .background(KUTheme.Palette.neutral100.ignoresSafeArea())
            .navigationTitle(item.status == .lost ? "I Found This" : "This Is Mine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showClaimSheet = false }
                        .foregroundStyle(KUTheme.Palette.primary700)
                }
            }
        }
    }

    // MARK: - Shared helpers

    private func contactCard(title: String, profile: ContactProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Font.Sarabun.semibold(13))
                .foregroundStyle(KUTheme.Palette.neutral600)
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(KUTheme.Palette.neutral200)
                    Image(systemName: "person.fill").font(.system(size: 14)).foregroundStyle(KUTheme.Palette.neutral400)
                }
                .frame(width: 32, height: 32)
                Text(profile.fullName)
                    .font(Font.Sarabun.semibold(14))
                    .foregroundStyle(KUTheme.Palette.neutral900)
            }
            let rows: [(String, String, String, Color)] = [
                profile.email.map    { ("envelope.fill",  "Email",     $0, KUTheme.Palette.primary700) },
                profile.phone.map    { ("phone.fill",     "Phone",     $0, KUTheme.Palette.success) },
                profile.instagram.map{ ("camera.fill",    "Instagram", "@\($0)", Color(hex: 0xE1306C)) },
                profile.lineId.map   { ("message.fill",   "LINE",      $0, Color(hex: 0x06C755)) },
            ].compactMap { $0 }

            if rows.isEmpty {
                Text("No contact info set yet.")
                    .font(Font.Sarabun.regular(12))
                    .foregroundStyle(KUTheme.Palette.neutral400)
            } else {
                VStack(spacing: 6) {
                    ForEach(rows, id: \.1) { icon, label, value, color in
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(color)
                                .frame(width: 20)
                            Text(label)
                                .font(Font.Sarabun.regular(12))
                                .foregroundStyle(KUTheme.Palette.neutral400)
                                .frame(width: 60, alignment: .leading)
                            Text(value)
                                .font(Font.Sarabun.medium(13))
                                .foregroundStyle(KUTheme.Palette.neutral900)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KUTheme.Palette.white,
                    in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                .stroke(KUTheme.Palette.success.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Location map preview

    private func locationMapPreview(_ coord: CLLocationCoordinate2D) -> some View {
        let tint: Color = item.status == .lost ? KUTheme.Palette.accent500 : KUTheme.Palette.primary700
        let region = MKCoordinateRegion(center: coord,
                                        span: MKCoordinateSpan(latitudeDelta: 0.004,
                                                               longitudeDelta: 0.004))
        return VStack(alignment: .leading, spacing: 8) {
            Text("Location on map")
                .font(Font.Sarabun.semibold(15))
                .foregroundStyle(KUTheme.Palette.neutral700)

            Map(position: .constant(.region(region))) {
                Annotation("", coordinate: coord, anchor: .bottom) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(tint)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(.white, lineWidth: 2.5))
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                            Text(item.emoji).font(.system(size: 16))
                        }
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(tint)
                            .offset(y: -2)
                    }
                    .allowsHitTesting(false)
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all))
            .allowsHitTesting(false)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                    .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
            )
        }
    }

    private func statusBanner(icon: String, text: String, color: Color, bg: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text).font(Font.Sarabun.medium(14))
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(bg, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 13))
            Text(msg).font(Font.Sarabun.medium(13))
        }
        .foregroundStyle(KUTheme.Palette.accent500)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(KUTheme.Palette.accent50, in: RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
    }

    // MARK: - Data loading

    private func loadAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadPhotos() }
            group.addTask { await loadClaims() }
            if let reporterId = item.reporterId {
                group.addTask { await loadContactProfile(userId: reporterId, into: .reporter) }
            }
        }
    }

    private enum ContactTarget { case reporter, claimer }

    private func loadContactProfile(userId: UUID, into target: ContactTarget) async {
        guard let profile = try? await supabase
            .from("profiles")
            .select("full_name, email, phone, instagram, line_id")
            .eq("id", value: userId.uuidString.lowercased())
            .single()
            .execute()
            .value as ContactProfile
        else { return }
        await MainActor.run {
            switch target {
            case .reporter: reporterContact = profile
            case .claimer:  approvedClaimerContact = profile
            }
        }
    }

    private func markReturned() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await supabase
                .from("items")
                .update(["status": "returned",
                         "returned_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: item.id.uuidString.lowercased())
                .execute()
            onItemUpdated?()
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func loadPhotos() async {
        struct ItemPhoto: Decodable { let storage_path: String }
        do {
            let photos: [ItemPhoto] = try await supabase
                .from("item_photos")
                .select("storage_path")
                .eq("item_id", value: item.id.uuidString.lowercased())
                .execute()
                .value
            let urls: [URL] = photos.compactMap { photo in
                try? supabase.storage.from("item-photos").getPublicURL(path: photo.storage_path)
            }
            await MainActor.run { photoURLs = urls }
        } catch {}
    }

    private func loadClaims() async {
        guard currentUserId != nil else { return }
        do {
            let claims: [Claim] = try await supabase
                .from("claims")
                .select()
                .eq("item_id", value: item.id.uuidString.lowercased())
                .execute()
                .value

            await MainActor.run {
                if isOwner {
                    incomingClaims = claims.filter { $0.state != .withdrawn }
                } else {
                    myClaim = claims.first { $0.claimerId == currentUserId }
                }
            }
            // Load claimer contact when owner sees an approved claim
            if isOwner, let approved = claims.first(where: { $0.state == .approved }) {
                await loadContactProfile(userId: approved.claimerId, into: .claimer)
            }
        } catch {}
    }

    // MARK: - Claim actions

    private func submitClaim() async {
        guard let userId = currentUserId else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        struct NewClaim: Encodable {
            let item_id: String
            let claimer_id: String
            let message: String?
            let state: String
        }
        let payload = NewClaim(
            item_id: item.id.uuidString.lowercased(),
            claimer_id: userId.uuidString.lowercased(),
            message: claimMessage.trimmingCharacters(in: .whitespaces).isEmpty ? nil : claimMessage.trimmingCharacters(in: .whitespaces),
            state: "pending"
        )
        do {
            let inserted: Claim = try await supabase
                .from("claims")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            await MainActor.run {
                myClaim = inserted
                showClaimSheet = false
                claimMessage = ""
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func withdrawClaim(_ claim: Claim) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let updated: Claim = try await supabase
                .from("claims")
                .update(["state": "withdrawn"])
                .eq("id", value: claim.id.uuidString.lowercased())
                .select()
                .single()
                .execute()
                .value
            await MainActor.run { myClaim = updated }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func decideClaim(_ claim: Claim, approve: Bool) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        let newState = approve ? "approved" : "rejected"
        do {
            let updated: Claim = try await supabase
                .from("claims")
                .update(["state": newState, "decided_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: claim.id.uuidString.lowercased())
                .select()
                .single()
                .execute()
                .value
            if approve {
                try await supabase
                    .from("items")
                    .update([
                        "status":     "claimed",
                        "claimed_by": claim.claimerId.uuidString.lowercased(),
                        "claimed_at": ISO8601DateFormatter().string(from: Date())
                    ])
                    .eq("id", value: item.id.uuidString.lowercased())
                    .execute()
                await loadContactProfile(userId: claim.claimerId, into: .claimer)
            }
            await MainActor.run {
                if let idx = incomingClaims.firstIndex(where: { $0.id == claim.id }) {
                    incomingClaims[idx] = updated
                }
            }
            if approve { onItemUpdated?() }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
}

// MARK: - Fullscreen photo viewer

private struct PhotoFullscreen: View {
    let urls: [URL]
    let startIndex: Int
    let onClose: () -> Void

    @State private var current = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $current) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFit()
                        case .failure:
                            Image(systemName: "photo").font(.system(size: 60)).foregroundStyle(.gray)
                        default: ProgressView().tint(.white)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.2), in: Circle())
                    }
                    .padding(.trailing, 16).padding(.top, 8)
                }
                Spacer()
                if urls.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(urls.indices, id: \.self) { i in
                            Circle()
                                .fill(i == current ? Color.white : Color.white.opacity(0.4))
                                .frame(width: i == current ? 8 : 6, height: i == current ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: current)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { current = startIndex }
    }
}

#Preview {
    ItemDetailScreen(item: SampleData.items[0], currentUserId: nil, onBack: {})
}
