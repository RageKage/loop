import CoreLocation
import Observation

/// Wraps CLLocationManager for use with Swift 6 / @Observable.
///
/// All observable state is updated on the main actor (implicit from
/// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor). CLLocationManager delivers
/// delegate callbacks on the thread it was created on — which is the main
/// thread here — so accessing @Observable properties in the delegate
/// methods is safe.
///
/// Falls back to downtown Minneapolis (44.9778, -93.2650) when the user
/// denies location access or the GPS hasn't resolved yet.
@Observable
final class LocationService: NSObject {

    // MARK: - Observed State

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var userLocation: CLLocation?

    /// The best available location. Views bind to this instead of checking
    /// userLocation directly so they automatically get the fallback.
    var effectiveLocation: CLLocation {
        userLocation ?? Self.minneapolisDowntown
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // MARK: - Constants

    static let minneapolisDowntown = CLLocation(latitude: 44.9778, longitude: -93.2650)

    // MARK: - Private

    private let manager: CLLocationManager

    // MARK: - Lifecycle

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // Capture any status that already exists (e.g. on re-launch after the user
        // already responded to the permission prompt).
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - API

    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            break   // Owning view shows the "Open Settings" alert
        @unknown default:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate

// @preconcurrency suppresses the Swift 6 actor-isolation mismatch that arises
// because CLLocationManagerDelegate predates Swift concurrency and is not yet
// annotated with @MainActor. The callbacks are delivered on the main thread
// (CLLocationManager was created on the main actor), so the assumption is safe.
extension LocationService: @preconcurrency CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: any Error) {
        // Non-fatal: effectiveLocation continues to return the Minneapolis fallback.
        print("[LocationService] \(error.localizedDescription)")
    }
}
