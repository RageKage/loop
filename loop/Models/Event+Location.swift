import CoreLocation

/// Location-related helpers on Event, kept separate to avoid importing
/// CoreLocation into the base model file.
extension Event {

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        clLocation.distance(from: location)
    }

    /// Miles from the given reference point, formatted for display ("0.8 mi", "< 0.1 mi").
    func distanceString(from location: CLLocation) -> String {
        let miles = clLocation.distance(from: location) / 1609.344
        if miles < 0.1 { return "< 0.1 mi" }
        return String(format: "%.1f mi", miles)
    }
}
