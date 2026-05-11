import SwiftUI
import Combine
@preconcurrency import MapKit

// MARK: - Completer for map search bar

private final class MapSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
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

// MARK: - MapPickerSheet

struct MapPickerSheet: View {
    @Binding var locationName: String
    @Binding var lat: Double?
    @Binding var lng: Double?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchCompleter = MapSearchCompleter()

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(center: KUCampus.center,
                           span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018))
    )
    @State private var pinCoordinate: CLLocationCoordinate2D? = nil
    @State private var pinName: String = ""
    @State private var isGeocoding = false
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapLayer
                VStack(spacing: 0) {
                    searchBar
                    if !searchCompleter.completions.isEmpty && searchFocused && !searchText.isEmpty {
                        suggestionsDropdown
                    }
                    Spacer()
                    if pinCoordinate != nil {
                        confirmBar
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KUTheme.Palette.primary700)
                }
            }
        }
    }

    // MARK: - Map
    // pointsOfInterest: .all renders the full Apple Maps POI layer natively —
    // all building labels appear just like in the Maps app, with no custom dot limit.

    private var mapLayer: some View {
        MapReader { proxy in
            Map(position: $position) {
                if let pin = pinCoordinate {
                    Annotation("", coordinate: pin, anchor: .bottom) {
                        pinMarker
                            .allowsHitTesting(false)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .all))
            .onTapGesture { screenPoint in
                guard let coord = proxy.convert(screenPoint, from: .local) else { return }
                searchFocused = false
                Task { await tapPin(at: coord) }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var pinMarker: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(KUTheme.Palette.accent500)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundStyle(KUTheme.Palette.accent500)
                .offset(y: -3)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pinCoordinate?.latitude)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(KUTheme.Palette.neutral400)
                .font(.system(size: 14))
            TextField("Search KU buildings…", text: $searchText)
                .font(Font.Sarabun.regular(14))
                .focused($searchFocused)
                .submitLabel(.search)
                .onChange(of: searchText) { _, new in searchCompleter.update(new) }
                .onSubmit { searchFocused = false }
            if !searchText.isEmpty {
                Button { searchText = ""; searchCompleter.update("") } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(KUTheme.Palette.neutral300)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(KUTheme.Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .kuShadow(KUTheme.Shadow.md)
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    // MARK: - Suggestions dropdown

    private var suggestionsDropdown: some View {
        let items = Array(searchCompleter.completions.prefix(7))
        return VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let c = items[i]
                Button {
                    Task { await resolveAndPan(c) }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(KUTheme.Palette.primary700)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 2) {
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if i < items.count - 1 {
                    Rectangle().fill(KUTheme.Palette.neutral100).frame(height: 1).padding(.leading, 14)
                }
            }
        }
        .background(KUTheme.Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .kuShadow(KUTheme.Shadow.md)
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
    }

    // MARK: - Confirm bar

    private var confirmBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(KUTheme.Palette.accent500)
                    .font(.system(size: 15))
                if isGeocoding {
                    ProgressView().scaleEffect(0.8)
                    Text("Getting location name…")
                        .font(Font.Sarabun.regular(14))
                        .foregroundStyle(KUTheme.Palette.neutral400)
                    Spacer()
                } else {
                    TextField("Location name", text: $pinName)
                        .font(Font.Sarabun.regular(15))
                }
            }
            .padding(12)
            .background(KUTheme.Palette.white)
            .clipShape(RoundedRectangle(cornerRadius: KUTheme.Radius.btn, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: KUTheme.Radius.btn).stroke(KUTheme.Palette.neutral200))

            PrimaryButton(label: "Confirm Location", icon: "checkmark.circle.fill") {
                locationName = pinName.isEmpty ? "KU Campus" : pinName
                lat = pinCoordinate?.latitude
                lng = pinCoordinate?.longitude
                dismiss()
            }
            .disabled(isGeocoding)
            .opacity(isGeocoding ? 0.6 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 32)
        .background(.ultraThinMaterial)
    }

    // MARK: - Tap handler
    // 1. Drop pin immediately so user gets visual feedback.
    // 2. Do a small-radius MKLocalSearch to find the nearest named POI — this
    //    returns the exact label shown on the map (e.g. "Faculty of Engineering
    //    Building 14 Chuchat Kamphu").
    // 3. Fall back to CLGeocoder if no POI is close enough.

    private func tapPin(at coord: CLLocationCoordinate2D) async {
        pinCoordinate = coord
        isGeocoding = true
        defer { isGeocoding = false }

        // MKLocalPointsOfInterestRequest returns ALL POIs within a radius
        // without needing a text query — empty naturalLanguageQuery returns nothing.
        let poiReq = MKLocalPointsOfInterestRequest(center: coord, radius: 150)
        if let resp = try? await MKLocalSearch(request: poiReq).start() {
            let nearest = resp.mapItems.min(by: {
                KUCampus.distanceMeters(from: $0.placemark.coordinate, to: coord) <
                KUCampus.distanceMeters(from: $1.placemark.coordinate, to: coord)
            })
            if let item = nearest,
               let name = item.name,
               KUCampus.distanceMeters(from: item.placemark.coordinate, to: coord) < 150 {
                pinName = name
                return
            }
        }

        // CLGeocoder fallback
        let geocoder = CLGeocoder()
        let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        if let marks = try? await geocoder.reverseGeocodeLocation(loc), let first = marks.first {
            pinName = first.name ?? first.thoroughfare ?? "KU Campus"
        } else {
            pinName = "KU Campus"
        }
    }

    // MARK: - Search result → pan + pin

    private func resolveAndPan(_ completion: MKLocalSearchCompletion) async {
        searchText = completion.title
        searchFocused = false

        let req = MKLocalSearch.Request(completion: completion)
        req.region = MKCoordinateRegion(
            center: KUCampus.center,
            span: MKCoordinateSpan(latitudeDelta: KUCampus.span.latDelta,
                                   longitudeDelta: KUCampus.span.lngDelta)
        )
        guard let resp = try? await MKLocalSearch(request: req).start(),
              let item = resp.mapItems.first else { return }

        let coord = item.placemark.coordinate
        withAnimation {
            position = .region(MKCoordinateRegion(center: coord,
                                                  span: MKCoordinateSpan(latitudeDelta: 0.005,
                                                                         longitudeDelta: 0.005)))
        }
        pinCoordinate = coord
        pinName = item.name ?? completion.title
    }
}
