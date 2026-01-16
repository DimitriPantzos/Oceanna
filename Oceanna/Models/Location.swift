import Foundation
import CoreLocation
import FirebaseFirestore

struct LocationData: Codable {
    var latitude: Double
    var longitude: Double
    var address: String?
    var city: String?
    var state: String?
    var country: String?
    var postalCode: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var geoPoint: GeoPoint {
        GeoPoint(latitude: latitude, longitude: longitude)
    }

    var displayString: String {
        if let city = city, let state = state {
            return "\(city), \(state)"
        }
        return address ?? "Unknown location"
    }

    init(
        latitude: Double,
        longitude: Double,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        country: String? = nil,
        postalCode: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    init(geoPoint: GeoPoint) {
        self.latitude = geoPoint.latitude
        self.longitude = geoPoint.longitude
    }
}

struct Hotspot: Identifiable, Codable {
    var id: String
    var name: String
    var description: String?
    var location: LocationData
    var category: HotspotCategory
    var activeFreelancerCount: Int
    var recentActivity: [String] // Recent post/project IDs
    var tags: [String]

    enum HotspotCategory: String, Codable, CaseIterable {
        case coworking = "Coworking Space"
        case cafe = "Cafe"
        case meetup = "Meetup Spot"
        case event = "Event"
        case creative = "Creative Hub"
        case other = "Other"
    }
}

struct CreativeCircle: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var location: LocationData
    var radius: Double // in miles
    var members: [String] // User IDs
    var admins: [String]
    var categories: [String]
    var isPublic: Bool
    var createdAt: Date
    var imageUrl: String?

    init(
        id: String? = nil,
        name: String,
        description: String,
        location: LocationData,
        radius: Double = 25,
        members: [String] = [],
        admins: [String] = [],
        categories: [String] = [],
        isPublic: Bool = true,
        createdAt: Date = Date(),
        imageUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.location = location
        self.radius = radius
        self.members = members
        self.admins = admins
        self.categories = categories
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.imageUrl = imageUrl
    }
}

extension CreativeCircle {
    static let example = CreativeCircle(
        id: "circle123",
        name: "Austin Creatives",
        description: "A community for creative professionals in the Austin area. Share work, find collaborators, and grow together.",
        location: LocationData(latitude: 30.2672, longitude: -97.7431, city: "Austin", state: "TX"),
        radius: 30,
        members: ["user123", "user456", "user789"],
        admins: ["user123"],
        categories: ["Design", "Photography", "Video"],
        imageUrl: nil
    )
}
