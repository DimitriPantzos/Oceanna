import Foundation
import FirebaseFirestore

struct Service: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var description: String
    var price: Double
    var priceType: PriceType

    enum PriceType: String, Codable, CaseIterable {
        case hourly = "per hour"
        case fixed = "fixed"
        case negotiable = "negotiable"
    }
}

struct PortfolioItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var description: String?
    var imageUrls: [String]
    var projectUrl: String?
    var createdAt: Date
    var tags: [String]
}

struct Availability: Codable {
    var isAvailable: Bool
    var hoursPerWeek: Int?
    var availableDays: [Int] // 0 = Sunday, 6 = Saturday
    var preferredContactTime: String?
}

struct FreelancerProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var skills: [String]
    var services: [Service]
    var portfolio: [PortfolioItem]
    var locationRadius: Double // in miles
    var availability: Availability
    var rating: Double
    var reviewCount: Int
    var hourlyRate: Double?
    var yearsOfExperience: Int?
    var languages: [String]
    var categories: [String]
    var isOpenToCollaboration: Bool
    var completedProjects: Int
    var responseTime: String? // e.g., "Usually responds within 1 hour"

    init(
        id: String? = nil,
        userId: String,
        skills: [String] = [],
        services: [Service] = [],
        portfolio: [PortfolioItem] = [],
        locationRadius: Double = 25,
        availability: Availability = Availability(isAvailable: true, hoursPerWeek: 40, availableDays: [1, 2, 3, 4, 5], preferredContactTime: nil),
        rating: Double = 0,
        reviewCount: Int = 0,
        hourlyRate: Double? = nil,
        yearsOfExperience: Int? = nil,
        languages: [String] = ["English"],
        categories: [String] = [],
        isOpenToCollaboration: Bool = true,
        completedProjects: Int = 0,
        responseTime: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.skills = skills
        self.services = services
        self.portfolio = portfolio
        self.locationRadius = locationRadius
        self.availability = availability
        self.rating = rating
        self.reviewCount = reviewCount
        self.hourlyRate = hourlyRate
        self.yearsOfExperience = yearsOfExperience
        self.languages = languages
        self.categories = categories
        self.isOpenToCollaboration = isOpenToCollaboration
        self.completedProjects = completedProjects
        self.responseTime = responseTime
    }
}

extension FreelancerProfile {
    static let example = FreelancerProfile(
        id: "profile123",
        userId: "user123",
        skills: ["UI/UX Design", "Figma", "Adobe XD", "Prototyping"],
        services: [
            Service(name: "Logo Design", description: "Custom logo design with multiple revisions", price: 150, priceType: .fixed),
            Service(name: "UI Design", description: "Complete UI design for mobile or web apps", price: 75, priceType: .hourly)
        ],
        portfolio: [
            PortfolioItem(title: "Brand Identity for Tech Startup", description: "Complete brand identity including logo, colors, and typography", imageUrls: [], createdAt: Date(), tags: ["branding", "logo"])
        ],
        locationRadius: 30,
        rating: 4.8,
        reviewCount: 47,
        hourlyRate: 75,
        yearsOfExperience: 5,
        categories: ["Design", "Branding"],
        completedProjects: 52,
        responseTime: "Usually responds within 2 hours"
    )
}
