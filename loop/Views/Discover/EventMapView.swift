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

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
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
        .onAppear {
            // Set the initial region once; the user can pan freely afterward.
            cameraPosition = .region(MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 5_000,
                longitudinalMeters: 5_000
            ))
        }
    }
}
