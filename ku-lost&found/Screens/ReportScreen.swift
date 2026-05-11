import SwiftUI
import PhotosUI
import MapKit
import Supabase

struct ReportScreen: View {
    let type: ItemStatus
    let onClose: () -> Void
    var onSubmitted: (() -> Void)? = nil

    @State private var name = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var lat: Double? = nil
    @State private var lng: Double? = nil
    @State private var notes = ""
    @State private var hintQuestion = ""
    @State private var category: ItemCategory = .other
    @State private var submitted = false
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var reportId = ""

    // Photo picker
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showPicker = false

    private var accent: Color { type == .lost ? KUTheme.Palette.accent700 : KUTheme.Palette.primary700 }
    private var accentBg: Color { type == .lost ? KUTheme.Palette.accent50 : KUTheme.Palette.primary50 }
    private var heroEmoji: String { type == .lost ? "😟" : "🙌" }
    private var title: String { type == .lost ? "Report Lost" : "Report Found" }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            if submitted {
                successView
            } else {
                formView
            }
        }
        .background(KUTheme.Palette.neutral100.ignoresSafeArea())
        .onChange(of: selectedItems) { _, newItems in
            Task { await loadImages(from: newItems) }
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        ZStack {
            Text(title)
                .font(Font.Sarabun.semibold(17))
                .foregroundStyle(KUTheme.Palette.neutral900)
            HStack {
                Button(action: onClose) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                        Text("Cancel").font(Font.Sarabun.regular(17))
                    }
                    .foregroundStyle(accent)
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

    // MARK: - Form

    private var formView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    photoSection

                    field("Item name") {
                        TextField("e.g. Blue backpack", text: $name)
                            .font(Font.Sarabun.regular(15))
                            .padding(12)
                            .background(KUTheme.Palette.white)
                            .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: KUTheme.Radius.btn).stroke(KUTheme.Palette.neutral200))
                    }

                    field("Date & time") {
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(KUTheme.Palette.white)
                            .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: KUTheme.Radius.btn).stroke(KUTheme.Palette.neutral200))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Location")
                            .font(Font.Sarabun.medium(13))
                            .foregroundStyle(KUTheme.Palette.neutral600)
                        LocationPickerField(locationName: $location, lat: $lat, lng: $lng, accent: accent)
                    }

                    field("Description") {
                        TextEditor(text: $notes)
                            .font(Font.Sarabun.regular(15))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .frame(minHeight: 110, alignment: .topLeading)
                            .background(KUTheme.Palette.white)
                            .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: KUTheme.Radius.btn).stroke(KUTheme.Palette.neutral200))
                            .overlay(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Add any helpful detail (color, brand, distinguishing marks)…")
                                        .font(Font.Sarabun.regular(14))
                                        .foregroundStyle(KUTheme.Palette.neutral400)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    field("Verification hint (optional)") {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("e.g. What colour is the wallet lining?", text: $hintQuestion)
                                .font(Font.Sarabun.regular(15))
                                .padding(12)
                                .background(KUTheme.Palette.white)
                                .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: KUTheme.Radius.btn).stroke(KUTheme.Palette.neutral200))
                            Text("Claimants must answer this. Only you see their answers.")
                                .font(Font.Sarabun.regular(11))
                                .foregroundStyle(KUTheme.Palette.neutral400)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(Font.Sarabun.medium(13))
                            .foregroundStyle(KUTheme.Palette.neutral600)
                        WrapHStack {
                            ForEach(SampleData.categories.dropFirst(), id: \.self) { c in
                                Button { category = c } label: {
                                    Text(c.label)
                                        .font(Font.Sarabun.medium(13))
                                        .foregroundStyle(category == c ? .white : KUTheme.Palette.neutral700)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(category == c ? accent : KUTheme.Palette.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(KUTheme.Palette.neutral200, lineWidth: category == c ? 0 : 1))
                                }
                                .buttonStyle(KUTappableStyle())
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 100)
            }

            VStack(spacing: 8) {
                if let err = errorMessage {
                    Text(err)
                        .font(Font.Sarabun.regular(13))
                        .foregroundStyle(KUTheme.Palette.accent500)
                        .multilineTextAlignment(.center)
                }
                PrimaryButton(
                    label: isBusy ? "Submitting…" : "Create Report",
                    icon: "paperplane.fill",
                    color: accent
                ) {
                    Task { await submitReport() }
                }
                .disabled(isBusy)
                .opacity(isBusy ? 0.7 : 1)
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if selectedImages.isEmpty {
                // Empty state tile
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    ZStack {
                        LinearGradient(
                            colors: [accentBg, KUTheme.Palette.white],
                            startPoint: .top, endPoint: .bottom
                        )
                        VStack(spacing: 6) {
                            Text(heroEmoji).font(.system(size: 56))
                            Text(type == .lost ? "I lost something" : "I found something")
                                .font(Font.Sarabun.semibold(14))
                                .foregroundStyle(accent)
                        }
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(accent)
                                        .frame(width: 44, height: 44)
                                        .kuShadow(KUTheme.Shadow.md)
                                    Image(systemName: "camera.fill")
                                        .foregroundStyle(.white)
                                }
                                .padding(12)
                            }
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                            .stroke(accent.opacity(0.4), lineWidth: 1.5)
                    )
                }
                .buttonStyle(KUTappableStyle())
            } else {
                // Photo preview grid
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Photos (\(selectedImages.count)/5)")
                            .font(Font.Sarabun.medium(13))
                            .foregroundStyle(KUTheme.Palette.neutral600)
                        Spacer()
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            Text("Edit")
                                .font(Font.Sarabun.medium(13))
                                .foregroundStyle(accent)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedImages.indices, id: \.self) { i in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: selectedImages[i])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.md, style: .continuous))

                                    Button {
                                        selectedImages.remove(at: i)
                                        if i < selectedItems.count {
                                            selectedItems.remove(at: i)
                                        }
                                    } label: {
                                        ZStack {
                                            Circle().fill(Color.black.opacity(0.6)).frame(width: 22, height: 22)
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(4)
                                }
                            }

                            if selectedImages.count < 5 {
                                PhotosPicker(
                                    selection: $selectedItems,
                                    maxSelectionCount: 5,
                                    matching: .images
                                ) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: KUTheme.Radius.md, style: .continuous)
                                            .fill(KUTheme.Palette.neutral100)
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: KUTheme.Radius.md)
                                                    .stroke(KUTheme.Palette.neutral200, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                            )
                                        VStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundStyle(accent)
                                            Text("Add")
                                                .font(Font.Sarabun.medium(12))
                                                .foregroundStyle(KUTheme.Palette.neutral400)
                                        }
                                    }
                                }
                            }
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
        }
    }

    // MARK: - Load images from picker

    private func loadImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        await MainActor.run { selectedImages = images }
    }

    // MARK: - Submit

    private func submitReport() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter an item name."
            return
        }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        struct NewItem: Encodable {
            let reporter_id: String
            let title: String
            let description: String
            let status: String
            let category: String
            let location_name: String
            let occurred_at: String
            let emoji: String
            let hint_question: String?
            let lat: Double?
            let lng: Double?
        }

        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            errorMessage = "Not signed in. Please sign in and try again."
            return
        }

        let emojis: [ItemCategory: String] = [
            .electronics: "📱", .clothing: "🧥", .idCard: "💳",
            .keys: "🔑", .bag: "🎒", .books: "📚", .other: "📦"
        ]
        let iso = ISO8601DateFormatter()
        let payload = NewItem(
            reporter_id: userId,
            title: name.trimmingCharacters(in: .whitespaces),
            description: notes.trimmingCharacters(in: .whitespaces),
            status: type.rawValue,
            category: category.rawValue,
            location_name: location.trimmingCharacters(in: .whitespaces),
            occurred_at: iso.string(from: date),
            emoji: emojis[category] ?? "📦",
            hint_question: hintQuestion.trimmingCharacters(in: .whitespaces).isEmpty ? nil : hintQuestion.trimmingCharacters(in: .whitespaces),
            lat: lat,
            lng: lng
        )

        do {
            let inserted: Item = try await supabase
                .from("items")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            reportId = inserted.id.uuidString

            // Upload photos if any were selected
            if !selectedImages.isEmpty {
                await uploadPhotos(itemId: inserted.id)
            }

            onSubmitted?()
            withAnimation(.spring()) { submitted = true }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Upload photos to Supabase Storage

    private func uploadPhotos(itemId: UUID) async {
        struct NewPhoto: Encodable {
            let item_id: String
            let storage_path: String
        }

        let userId = (try? await supabase.auth.session.user.id.uuidString) ?? "unknown"

        for (index, image) in selectedImages.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            // Path must start with user's UUID (lowercase) to satisfy RLS: auth.uid() = foldername[1]
            let path = "\(userId.lowercased())/\(itemId.uuidString.lowercased())/\(index + 1).jpg"

            do {
                try await supabase.storage
                    .from("item-photos")
                    .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))

                let photo = NewPhoto(item_id: itemId.uuidString, storage_path: path)
                try await supabase
                    .from("item_photos")
                    .insert(photo)
                    .execute()
            } catch {
                // Non-fatal — item was created, photo upload failed silently
            }
        }
    }

    // MARK: - Helpers

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.Sarabun.medium(13))
                .foregroundStyle(KUTheme.Palette.neutral600)
            content()
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(KUTheme.Palette.successBg)
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(KUTheme.Palette.success)
                ConfettiBurst()
            }
            VStack(spacing: 6) {
                Text(type == .lost ? "Report submitted" : "Thanks for helping!")
                    .font(Font.Sarabun.bold(22))
                    .foregroundStyle(KUTheme.Palette.neutral900)
                Text("Report ID: KU-\(reportId.prefix(8))")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(KUTheme.Palette.neutral600)
            }
            VStack(alignment: .leading, spacing: 12) {
                summaryRow(label: "Item", value: name.isEmpty ? "—" : name)
                summaryRow(label: "Location", value: location.isEmpty ? "—" : location)
                summaryRow(label: "When", value: date.formatted(date: .abbreviated, time: .shortened))
                if !selectedImages.isEmpty {
                    summaryRow(label: "Photos", value: "\(selectedImages.count) uploaded")
                }
                if let la = lat, let ln = lng {
                    let coord = CLLocationCoordinate2D(latitude: la, longitude: ln)
                    let region = MKCoordinateRegion(center: coord,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                    Map(position: .constant(.region(region))) {
                        Annotation("", coordinate: coord, anchor: .bottom) {
                            VStack(spacing: 0) {
                                ZStack {
                                    Circle().fill(accent).frame(width: 26, height: 26)
                                        .overlay(Circle().stroke(.white, lineWidth: 2))
                                    Image(systemName: "mappin")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                Image(systemName: "arrowtriangle.down.fill")
                                    .font(.system(size: 7))
                                    .foregroundStyle(accent)
                                    .offset(y: -2)
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                    .allowsHitTesting(false)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.md, style: .continuous))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
            .kuShadow()
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(label: "Done", color: accent, action: onClose)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Font.Sarabun.regular(13))
                .foregroundStyle(KUTheme.Palette.neutral400)
            Spacer()
            Text(value)
                .font(Font.Sarabun.medium(14))
                .foregroundStyle(KUTheme.Palette.neutral900)
                .lineLimit(1)
        }
    }
}

// MARK: - Flow layout for category chips

private struct WrapHStack<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], alignment: .leading, spacing: 8) {
            content
        }
    }
}

// MARK: - Confetti burst animation

private struct ConfettiBurst: View {
    @State private var go = false
    private let pieces: [(Color, CGFloat, CGFloat, Double)] = [
        (KUTheme.Palette.accent500, -56, -42, -28),
        (KUTheme.Palette.primary700, 60, -36, 32),
        (KUTheme.Palette.lostText, -48, 52, 18),
        (Color(hex: 0xFFC107), 54, 48, -22),
        (KUTheme.Palette.primary200, -68, 6, 12),
        (KUTheme.Palette.accent500, 70, 4, -14),
    ]

    var body: some View {
        ZStack {
            ForEach(pieces.indices, id: \.self) { i in
                let p = pieces[i]
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.0)
                    .frame(width: 7, height: 7)
                    .offset(x: go ? p.1 : 0, y: go ? p.2 : 0)
                    .rotationEffect(.degrees(go ? p.3 : 0))
                    .opacity(go ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.2)) { go = true }
        }
    }
}

#Preview { ReportScreen(type: .lost, onClose: {}) }
