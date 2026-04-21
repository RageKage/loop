import CoreLocation
import MapKit
import SwiftUI

/// MapKit map showing event pins color-coded by category.
/// Tapping a pin sets selectedEvent, which the parent view presents as a sheet.
///
/// Camera starts centered on the user's location (or the Minneapolis fallback)
/// at a ~5 km radius. The user can freely pan from there.
struct EventMapView: View {
    let events: [Event]
    @Binding var selectedEvent: Event?
    let userLocation: CLLocation
    /// True when there are no events at all and no filters are active.
    let isGloballyEmpty: Bool
    let onSwitchToCreate: () -> Void

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showNoEventsInAreaBanner = false

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(events) { event in
                    Annotation("", coordinate: event.coordinate) {
                        EventPinView(category: event.categoryEnum)
                            .onTapGesture { selectedEvent = event }
                    }
                    .annotationTitles(.hidden)
                }
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapUserLocationButton()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                guard !events.isEmpty else {
                    showNoEventsInAreaBanner = false
                    return
                }
                let region = context.region
                let hasVisible = events.contains { event in
                    let coord = event.coordinate
                    return abs(coord.latitude  - region.center.latitude)  <= region.span.latitudeDelta  / 2
                        && abs(coord.longitude - region.center.longitude) <= region.span.longitudeDelta / 2
                }
                withAnimation(.easeInOut) {
                    showNoEventsInAreaBanner = !hasVisible
                }
            }

            // ── Floating overlay: "no events in this area" banner ────────
            VStack(spacing: 0) {
                if showNoEventsInAreaBanner {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.slash")
                        Text("No events in this area. Try zooming out.")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.easeInOut, value: showNoEventsInAreaBanner)

            // ── Global empty state (semi-transparent, map still visible) ──
            if isGloballyEmpty {
                Color(.systemBackground)
                    .opacity(0.85)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "map")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No events nearby yet")
                        .font(.headline)
                    Text("Be the first to post one! Events you or others create will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Create an Event", action: onSwitchToCreate)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            cameraPosition = .region(MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 5_000,
                longitudinalMeters: 5_000
            ))
        }
    }
}
