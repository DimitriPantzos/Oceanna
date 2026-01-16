import Foundation
import CoreLocation
import FirebaseFirestore

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published var currentLocation: CLLocation?
    @Published var currentLocationData: LocationData?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var error: LocationError?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    enum LocationError: LocalizedError {
        case denied
        case restricted
        case unavailable
        case geocodingFailed

        var errorDescription: String? {
            switch self {
            case .denied:
                return "Location access denied. Please enable location services in Settings."
            case .restricted:
                return "Location access is restricted on this device."
            case .unavailable:
                return "Unable to determine your location."
            case .geocodingFailed:
                return "Unable to determine address for this location."
            }
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }

        isLoading = true
        error = nil
        locationManager.requestLocation()
    }

    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }

        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func reverseGeocode(location: CLLocation) async -> LocationData? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            return LocationData(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                address: placemark.thoroughfare,
                city: placemark.locality,
                state: placemark.administrativeArea,
                country: placemark.country,
                postalCode: placemark.postalCode
            )
        } catch {
            self.error = .geocodingFailed
            return nil
        }
    }

    func geocode(address: String) async -> LocationData? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            guard let placemark = placemarks.first,
                  let location = placemark.location else { return nil }

            return LocationData(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                address: placemark.thoroughfare,
                city: placemark.locality,
                state: placemark.administrativeArea,
                country: placemark.country,
                postalCode: placemark.postalCode
            )
        } catch {
            self.error = .geocodingFailed
            return nil
        }
    }

    // MARK: - Helper Methods

    func distance(from location1: CLLocation, to location2: CLLocation) -> Double {
        return location1.distance(from: location2) / 1609.34 // Convert meters to miles
    }

    func distance(from geoPoint1: GeoPoint, to geoPoint2: GeoPoint) -> Double {
        let location1 = CLLocation(latitude: geoPoint1.latitude, longitude: geoPoint1.longitude)
        let location2 = CLLocation(latitude: geoPoint2.latitude, longitude: geoPoint2.longitude)
        return distance(from: location1, to: location2)
    }

    func isWithinRadius(_ location: GeoPoint, center: GeoPoint, radiusMiles: Double) -> Bool {
        return distance(from: location, to: center) <= radiusMiles
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.currentLocation = location
            self.isLoading = false

            Task {
                self.currentLocationData = await self.reverseGeocode(location: location)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false

            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.error = .denied
                case .locationUnknown:
                    self.error = .unavailable
                default:
                    self.error = .unavailable
                }
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.requestCurrentLocation()
            case .denied:
                self.error = .denied
            case .restricted:
                self.error = .restricted
            default:
                break
            }
        }
    }
}
