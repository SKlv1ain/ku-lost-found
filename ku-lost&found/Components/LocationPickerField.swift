import SwiftUI
import Combine
@preconcurrency import MapKit

// MARK: - MKLocalSearchCompleter wrapper

private final class LocationCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    private let inner = MKLocalSearchCompleter()

    override init() {
        super.init()
        inner.delegate = self
        inner.region = MKCoordinateRegion(
            center: KUCampus.center,
            span: MKCoordinateSpan(latitudeDelta: KUCampus.span.latDelta,
                                   longitudeDelta: KUCampus.span.lngDelta)
        )
        inner.resultTypes = [.pointOfInterest, .query]
    }

    func update(_ query: String) { inner.queryFragment = query }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let r = completer.results
        DispatchQueue.main.async { self.completions = r }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async { self.completions = [] }
    }
}

// MARK: - LocationPickerField

struct LocationPickerField: View {
    @Binding var locationName: String
    @Binding var lat: Double?
    @Binding var lng: Double?
    var accent: Color = KUTheme.Palette.primary700

    @StateObject private var completer = LocationCompleter()
    @State private var isResolving = false
    @State private var showMapPicker = false
    @FocusState private var isFocused: Bool

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            inputRow
            if !completer.completions.isEmpty && isFocused && !locationName.isEmpty {
                suggestionsView
            }
            if let coord = coordinate, !isFocused {
                mapPreview(coord)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinate != nil)
        .sheet(isPresented: $showMapPicker) {
            MapPickerSheet(locationName: $locationName, lat: $lat, lng: $lng)
        }
    }

    // MARK: - Input row

    private var inputRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(accent)
                .font(.system(size: 15))

            TextField("Where did it happen?", text: $locationName)
                .font(Font.Sarabun.regular(15))
                .focused($isFocused)
                .onChange(of: locationName) { _, new in
                    if isFocused { lat = nil; lng = nil }
                    completer.update(new)
                }

            if isResolving {
                ProgressView().scaleEffect(0.8)
            } else {
                Divider().frame(height: 18)
                Button {
                    isFocused = false
                    showMapPicker = true
                } label: {
                    Image(systemName: "map.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 28, height: 28)
                        .background(accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(KUTappableStyle())
            }
        }
        .padding(12)
        .background(KUTheme.Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous)
                .stroke(isFocused ? accent.opacity(0.6) : KUTheme.Palette.neutral200,
                        lineWidth: isFocused ? 1.5 : 1)
        )
    }

    // MARK: - Suggestions dropdown

    private var suggestionsView: some View {
        let items = Array(completer.completions.prefix(7))
        return VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let c = items[i]
                Button { Task { await resolve(c) } } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(accent)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(c.title)
                                .font(Font.Sarabun.medium(14))
                                .foregroundStyle(KUTheme.Palette.neutral900)
                            if !c.subtitle.isEmpty {
                                Text(c.subtitle)
                                    .font(Font.Sarabun.regular(12))
                                    .foregroundStyle(KUTheme.Palette.neutral400)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if i < items.count - 1 {
                    Rectangle().fill(KUTheme.Palette.neutral100).frame(height: 1).padding(.leading, 12)
                }
            }
        }
        .background(KUTheme.Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: KUTheme.Radius.md, style: .continuous)
                .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
        )
        .kuShadow(KUTheme.Shadow.md)
    }

    // MARK: - Map preview

    private func mapPreview(_ coord: CLLocationCoordinate2D) -> some View {
        let region = MKCoordinateRegion(center: coord,
                                        span: MKCoordinateSpan(latitudeDelta: 0.004,
                                                               longitudeDelta: 0.004))
        return ZStack(alignment: .topTrailing) {
            Map(position: .constant(.region(region))) {
                Annotation("", coordinate: coord, anchor: .bottom) { previewPin }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .allowsHitTesting(false)
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KUTheme.Radius.lg, style: .continuous)
                    .stroke(KUTheme.Palette.neutral200, lineWidth: 1)
            )

            Button { showMapPicker = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "pencil").font(.system(size: 11, weight: .semibold))
                    Text("Change").font(Font.Sarabun.medium(12))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.55), in: Capsule())
            }
            .buttonStyle(KUTappableStyle())
            .padding(8)
        }
    }

    private var previewPin: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(accent).frame(width: 28, height: 28)
                    .overlay(Circle().stroke(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                Image(systemName: "mappin").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8)).foregroundStyle(accent).offset(y: -2)
        }
    }

    // MARK: - Resolve completion → coordinate

    private func resolve(_ completion: MKLocalSearchCompletion) async {
        isResolving = true
        isFocused = false
        locationName = completion.title

        let req = MKLocalSearch.Request(completion: completion)
        req.region = MKCoordinateRegion(
            center: KUCampus.center,
            span: MKCoordinateSpan(latitudeDelta: KUCampus.span.latDelta,
                                   longitudeDelta: KUCampus.span.lngDelta)
        )
        if let resp = try? await MKLocalSearch(request: req).start(),
           let item = resp.mapItems.first {
            lat = item.placemark.coordinate.latitude
            lng = item.placemark.coordinate.longitude
            locationName = item.name ?? completion.title
        }
        isResolving = false
    }
}
