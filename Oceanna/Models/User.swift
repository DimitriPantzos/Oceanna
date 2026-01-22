import Foundation
import FirebaseFirestore

// MARK: - Availability
enum Availability: String, Codable, CaseIterable {
    case inPerson = "in_person"
    case remote = "remote"
    case both = "both"

    var displayName: String {
        switch self {
        case .inPerson: return "In-Person"
        case .remote: return "Remote"
        case .both: return "In-Person & Remote"
        }
    }
}

// MARK: - Approval Status
enum ApprovalStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case waitlisted = "waitlisted"
}

// MARK: - Profile Visibility
struct ProfileVisibility: Codable, Equatable {
    var showSkills: Bool = true
    var showPortfolio: Bool = true
    var showBio: Bool = true
    var showCity: Bool = true

    init(showSkills: Bool = true, showPortfolio: Bool = true, showBio: Bool = true, showCity: Bool = true) {
        self.showSkills = showSkills
        self.showPortfolio = showPortfolio
        self.showBio = showBio
        self.showCity = showCity
    }
}

// MARK: - User Model
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var avatarUrl: String?
    var city: String
    var isHireable: Bool
    var availability: Availability
    var skills: [String]
    var lookingFor: [String]
    var bio: String?
    var isVerified: Bool
    var approvalStatus: ApprovalStatus
    var visibility: ProfileVisibility
    var createdAt: Date

    var initials: String {
        let names = displayName.split(separator: " ")
        let firstInitial = names.first?.first ?? "?"
        let lastInitial = names.count > 1 ? names.last?.first : nil
        return "\(firstInitial)\(lastInitial ?? Character(""))"
    }

    var availabilityBadge: String {
        "\(city) · \(availability.displayName)"
    }

    var topSkill: String? {
        skills.first
    }

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        avatarUrl: String? = nil,
        city: String = "",
        isHireable: Bool = true,
        availability: Availability = .both,
        skills: [String] = [],
        lookingFor: [String] = [],
        bio: String? = nil,
        isVerified: Bool = false,
        approvalStatus: ApprovalStatus = .pending,
        visibility: ProfileVisibility = ProfileVisibility(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.city = city
        self.isHireable = isHireable
        self.availability = availability
        self.skills = skills
        self.lookingFor = lookingFor
        self.bio = bio
        self.isVerified = isVerified
        self.approvalStatus = approvalStatus
        self.visibility = visibility
        self.createdAt = createdAt
    }
}

extension User {
    static let example = User(
        id: "user123",
        email: "sarah@example.com",
        displayName: "Sarah Chen",
        city: "Brooklyn, NY",
        isHireable: true,
        availability: .both,
        skills: ["UI/UX Design", "Figma", "Branding"],
        lookingFor: ["Photography", "Illustration"],
        bio: "Creative director with a passion for minimal design.",
        isVerified: true,
        approvalStatus: .approved
    )

    static let pendingExample = User(
        id: "user456",
        email: "pending@example.com",
        displayName: "New User",
        city: "Los Angeles, CA",
        approvalStatus: .pending
    )
}
