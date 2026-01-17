import Foundation
import FirebaseFirestore

struct PortfolioItem: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var imageUrl: String
    var title: String
    var description: String?
    var tags: [String]
    var createdAt: Date

    init(
        id: String? = nil,
        userId: String,
        imageUrl: String,
        title: String,
        description: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.imageUrl = imageUrl
        self.title = title
        self.description = description
        self.tags = tags
        self.createdAt = createdAt
    }
}

extension PortfolioItem {
    static let example = PortfolioItem(
        id: "portfolio123",
        userId: "user123",
        imageUrl: "https://example.com/image.jpg",
        title: "Brand Identity for Coffee Shop",
        description: "Complete visual identity including logo, packaging, and signage.",
        tags: ["Branding", "Logo Design", "Packaging"]
    )
}
