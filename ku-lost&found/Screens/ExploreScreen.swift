import SwiftUI
import MapKit

struct ExploreScreen: View {
    var itemsVM: ItemsViewModel
    var onItem: (Item) -> Void

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(center: SampleData.kuCenter,
                           span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012))
    )
    @State private var selected: Item? = nil

    private var pinned: [Item] { itemsVM.items.filter { $0.coordinate != nil } }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
                ForEach(pinned) { item in
                    Annotation(item.title, coordinate: item.coordinate!) {
                        MapPin(item: item, isSelected: selected?.id == item.id) {
                            selected = item
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .ignoresSafeArea(edges: .bottom)

            topControls

            if let s = selected {
                VStack { Spacer()
                    MapBottomCard(item: s,
                                  onClose: { selected = nil },
                                  onView:  { onItem(s) })
                        .padding(.horizontal, 14)
                        .padding(.bottom, 96)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selected?.id)
    }

    private var topControls: some View {
        HStack(spacing: 10) {
            CircleFAB(systemName: "chevron.left") {}
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(KUTheme.Palette.primary700)
                Text("Search the map…")
                    .font(Font.Sarabun.regular(14))
                    .foregroundStyle(KUTheme.Palette.neutral400)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(KUTheme.Palette.white)
            .clipShape(Capsule())
            .kuShadow(KUTheme.Shadow.md)

            CircleFAB(systemName: "location.fill") {
                withAnimation {
                    position = .region(MKCoordinateRegion(
                        center: SampleData.kuCenter,
                        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }
}

private struct CircleFAB: View {
    let systemName: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(KUTheme.Palette.primary700)
                .frame(width: 40, height: 40)
                .background(KUTheme.Palette.white)
                .clipShape(Circle())
                .kuShadow(KUTheme.Shadow.md)
        }
        .buttonStyle(KUTappableStyle())
    }
}

private struct MapPin: View {
    let item: Item
    let isSelected: Bool
    let onTap: () -> Void

    private var tint: Color {
        item.status == .lost ? KUTheme.Palette.lostText : KUTheme.Palette.primary700
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(tint)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .kuShadow(KUTheme.Shadow.md)
                    Text(item.emoji).font(.system(size: 18))
                }
                Triangle().fill(tint)
                    .frame(width: 12, height: 8)
                    .offset(y: -1)
            }
            .scaleEffect(isSelected ? 1.15 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

private struct MapBottomCard: View {
    let item: Item
    let onClose: () -> Void
    let onView: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: KUTheme.Radius.md, style: .continuous)
                        .fill(item.status == .lost ? KUTheme.Palette.accent50 : KUTheme.Palette.primary50)
                    Text(item.emoji).font(.system(size: 28))
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(Font.Sarabun.semibold(16))
                        .foregroundStyle(KUTheme.Palette.neutral900)
                    Text(item.location)
                        .font(Font.Sarabun.regular(13))
                        .foregroundStyle(KUTheme.Palette.neutral600)
                    HStack(spacing: 8) {
                        StatusBadge(status: item.status)
                        Text(item.time)
                            .font(Font.Sarabun.regular(11))
                            .foregroundStyle(KUTheme.Palette.neutral400)
                    }
                }
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KUTheme.Palette.neutral400)
                        .padding(8)
                }
            }
            HStack(spacing: 10) {
                Button(action: {}) {
                    Text("I saw this")
                        .font(Font.Sarabun.semibold(14))
                        .foregroundStyle(KUTheme.Palette.primary700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .overlay(
                            RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                                .stroke(KUTheme.Palette.primary700, lineWidth: 1.5)
                        )
                }
                .buttonStyle(KUTappableStyle())
                PrimaryButton(label: "View details", action: onView)
            }
        }
        .padding(16)
        .background(KUTheme.Palette.white, in: RoundedRectangle(cornerRadius: KUTheme.Radius.xl, style: .continuous))
        .kuShadow(KUTheme.Shadow.md)
    }
}

#Preview { ExploreScreen(itemsVM: ItemsViewModel(), onItem: { _ in }) }
