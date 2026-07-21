import Foundation
import CoreLocation

/// Resolves the user's country name for prompt enrichment.
protocol CountryProviding {
    func resolveCountryName() async -> String?
}

/// Wraps CLLocationManager: requests when-in-use permission on app entry and
/// resolves the latest location to an English country name. Falls back to the
/// device region whenever permission/location/geocoding is unavailable so the
/// flow never breaks. Never stores or transmits coordinates.
final class LocationManager: NSObject, ObservableObject, CountryProviding {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastLocation: CLLocation?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Shows the system prompt only when authorization is `notDetermined`.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func resolveCountryName() async -> String? {
        if let location = lastLocation,
           let placemarks = try? await geocoder.reverseGeocodeLocation(location),
           let name = GiftSuggestionInputBuilder.countryName(
               fromRegionCode: placemarks.first?.isoCountryCode) {
            return name
        }
        return GiftSuggestionInputBuilder.deviceRegionCountryName()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Ignore: resolveCountryName() falls back to the device region.
    }
}
