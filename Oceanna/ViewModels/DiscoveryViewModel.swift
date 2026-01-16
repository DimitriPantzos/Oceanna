import Foundation
import MapKit
import FirebaseFirestore

@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var freelancers: [FreelancerProfile] = []
    @Published var selectedFreelancer: FreelancerProfile?
    @Published var projects: [Project] = []
    @Published var hotspots: [Hotspot] = []
    @Published var circles: [CreativeCircle] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Map state
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default: SF
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var searchRadius: Double = 25 // miles

    // Filters
    @Published var selectedCategory: String?
    @Published var selectedSkills: [String] = []
    @Published var minRating: Double?
    @Published var maxBudget: Double?
    @Published var availableOnly: Bool = false

    private let firestoreService = FirestoreService.shared
    private let locationService = LocationService.shared
    private let matchingService = MatchingService.shared

    // MARK: - Load Data

    func loadNearbyFreelancers() async {
        isLoading = true
        defer { isLoading = false }

        let center = GeoPoint(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )

        do {
            freelancers = try await firestoreService.getNearbyFreelancers(
                center: center,
                radiusMiles: searchRadius,
                category: selectedCategory
            )

            // Apply additional filters
            if let minRating = minRating {
                freelancers = freelancers.filter { $0.rating >= minRating }
            }

            if availableOnly {
                freelancers = freelancers.filter { $0.availability.isAvailable }
            }

            if !selectedSkills.isEmpty {
                freelancers = freelancers.filter { freelancer in
                    !Set(freelancer.skills).isDisjoint(with: Set(selectedSkills))
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadOpenProjects() async {
        isLoading = true
        defer { isLoading = false }

        let location = GeoPoint(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )

        do {
            projects = try await firestoreService.getOpenProjects(
                near: location,
                category: selectedCategory
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCreativeCircles() async {
        let location = GeoPoint(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )

        do {
            circles = try await firestoreService.getCreativeCircles(
                near: location,
                radiusMiles: searchRadius
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Location Updates

    func centerOnUserLocation() {
        if let location = locationService.currentLocation {
            region.center = location.coordinate
            Task {
                await loadNearbyFreelancers()
            }
        } else {
            locationService.requestCurrentLocation()
        }
    }

    func updateSearchRadius(_ radius: Double) {
        searchRadius = radius
        Task {
            await loadNearbyFreelancers()
        }
    }

    // MARK: - Filters

    func applyFilters() async {
        await loadNearbyFreelancers()
    }

    func clearFilters() {
        selectedCategory = nil
        selectedSkills = []
        minRating = nil
        maxBudget = nil
        availableOnly = false

        Task {
            await loadNearbyFreelancers()
        }
    }

    // MARK: - Selection

    func selectFreelancer(_ freelancer: FreelancerProfile) {
        selectedFreelancer = freelancer
    }

    func clearSelection() {
        selectedFreelancer = nil
    }

    // MARK: - Swipe Mode

    @Published var swipeProfiles: [FreelancerProfile] = []
    @Published var currentSwipeIndex = 0
    @Published var connections: [String] = [] // Freelancer IDs user has connected with

    func loadSwipeProfiles(for user: User) async {
        let location = locationService.currentLocation.map {
            GeoPoint(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        }

        do {
            swipeProfiles = try await matchingService.getSwipeProfiles(
                for: user,
                location: location,
                radiusMiles: searchRadius
            )
            currentSwipeIndex = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func swipeRight(on freelancer: FreelancerProfile) {
        guard let id = freelancer.id else { return }
        connections.append(id)
        advanceSwipe()
    }

    func swipeLeft() {
        advanceSwipe()
    }

    private func advanceSwipe() {
        if currentSwipeIndex < swipeProfiles.count - 1 {
            currentSwipeIndex += 1
        }
    }

    var currentSwipeProfile: FreelancerProfile? {
        guard currentSwipeIndex < swipeProfiles.count else { return nil }
        return swipeProfiles[currentSwipeIndex]
    }
}

// MARK: - Categories

extension DiscoveryViewModel {
    static let categories = [
        "Design",
        "Development",
        "Photography",
        "Video",
        "Music & Audio",
        "Writing",
        "Marketing",
        "Art & Illustration",
        "Animation",
        "Consulting"
    ]

    static let popularSkills = [
        "UI/UX Design",
        "Graphic Design",
        "Logo Design",
        "Web Development",
        "iOS Development",
        "Android Development",
        "Photography",
        "Video Editing",
        "Motion Graphics",
        "Copywriting",
        "Social Media",
        "SEO",
        "Illustration",
        "3D Modeling",
        "Voice Over"
    ]
}
