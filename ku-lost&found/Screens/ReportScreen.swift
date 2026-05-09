import SwiftUI

struct ReportScreen: View {
    let type: ItemStatus       // .lost or .found
    let onClose: () -> Void

    @State private var name = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var notes = ""
    @State private var category: ItemCategory = .other
    @State private var submitted = false
    @State private var reportId = Int.random(in: 1000...9999)

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
    }

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
                    photoTile

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

                    field("Location") {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(accent)
                            TextField("Where did it happen?", text: $location)
                                .font(Font.Sarabun.regular(15))
                        }
                        .padding(12)
                        .background(KUTheme.Palette.white)
                        .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: KUTheme.Radius.btn).stroke(KUTheme.Palette.neutral200))
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(Font.Sarabun.medium(13))
                            .foregroundStyle(KUTheme.Palette.neutral600)
                        WrapHStack {
                            ForEach(SampleData.categories.dropFirst(), id: \.self) { c in
                                Button { category = c } label: {
                                    Text(c.rawValue)
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

            VStack {
                PrimaryButton(label: "Create Report", icon: "paperplane.fill", color: accent) {
                    withAnimation(.spring()) { submitted = true }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
    }

    private var photoTile: some View {
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
                    Button(action: {}) {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(accent)
                            .clipShape(Circle())
                            .kuShadow(KUTheme.Shadow.md)
                    }
                    .buttonStyle(KUTappableStyle())
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
                Text("Report ID: KU-\(reportId)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(KUTheme.Palette.neutral600)
            }
            VStack(alignment: .leading, spacing: 8) {
                summaryRow(label: "Item", value: name.isEmpty ? "—" : name)
                summaryRow(label: "Location", value: location.isEmpty ? "—" : location)
                summaryRow(label: "When", value: date.formatted(date: .abbreviated, time: .shortened))
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

// Simple flow layout for category chips
private struct WrapHStack<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        FlowLayout(spacing: 8) { content }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > width { x = 0; y += lineH + spacing; lineH = 0 }
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
        return CGSize(width: width, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX { x = bounds.minX; y += lineH + spacing; lineH = 0 }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
    }
}

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
