import Foundation
import FirebaseFirestore

enum UserType: String, Codable, CaseIterable {
    case freelancer
    case client
}

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var avatarUrl: String?
    var userType: UserType
    var isVerified: Bool
    var createdAt: Date
    var location: GeoPoint?
    var bio: String?

    var initials: String {
        let names = displayName.split(separator: " ")
        let firstInitial = names.first?.first ?? "?"
        let lastInitial = names.count > 1 ? names.last?.first : nil
        return "\(firstInitial)\(lastInitial ?? Character(""))"
    }

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        avatarUrl: String? = nil,
        userType: UserType,
        isVerified: Bool = false,
        createdAt: Date = Date(),
        location: GeoPoint? = nil,
        bio: String? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.userType = userType
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.location = location
        self.bio = bio
    }
}

extension User {
    static let example = User(
        id: "user123",
        email: "john@example.com",
        displayName: "John Doe",
        userType: .freelancer,
        isVerified: true,
        bio: "Creative designer with 5 years of experience"
    )
}
