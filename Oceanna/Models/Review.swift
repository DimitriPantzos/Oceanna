import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var projectId: String
    var reviewerId: String
    var revieweeId: String
    var reviewerType: UserType // Was this review written by a freelancer or client?
    var rating: Double
    var title: String?
    var content: String
    var createdAt: Date
    var isPublic: Bool
    var response: ReviewResponse?
    var helpfulCount: Int
    var categories: [CategoryRating]

    struct CategoryRating: Codable {
        var category: String
        var rating: Double
    }

    struct ReviewResponse: Codable {
        var content: String
        var createdAt: Date
    }

    init(
        id: String? = nil,
        projectId: String,
        reviewerId: String,
        revieweeId: String,
        reviewerType: UserType,
        rating: Double,
        title: String? = nil,
        content: String,
        createdAt: Date = Date(),
        isPublic: Bool = true,
        response: ReviewResponse? = nil,
        helpfulCount: Int = 0,
        categories: [CategoryRating] = []
    ) {
        self.id = id
        self.projectId = projectId
        self.reviewerId = reviewerId
        self.revieweeId = revieweeId
        self.reviewerType = reviewerType
        self.rating = rating
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.isPublic = isPublic
        self.response = response
        self.helpfulCount = helpfulCount
        self.categories = categories
    }
}

extension Review {
    static let clientReviewExample = Review(
        id: "review123",
        projectId: "project123",
        reviewerId: "client123",
        revieweeId: "user123",
        reviewerType: .client,
        rating: 5.0,
        title: "Exceptional work!",
        content: "John delivered amazing work on our mural project. He was professional, creative, and finished ahead of schedule. Highly recommend!",
        categories: [
            CategoryRating(category: "Quality", rating: 5.0),
            CategoryRating(category: "Communication", rating: 5.0),
            CategoryRating(category: "Timeliness", rating: 5.0),
            CategoryRating(category: "Professionalism", rating: 5.0)
        ]
    )

    static let freelancerReviewExample = Review(
        id: "review456",
        projectId: "project123",
        reviewerId: "user123",
        revieweeId: "client123",
        reviewerType: .freelancer,
        rating: 4.5,
        title: "Great client to work with",
        content: "Clear communication and prompt payments. The project scope was well-defined and they were open to creative suggestions.",
        categories: [
            CategoryRating(category: "Communication", rating: 5.0),
            CategoryRating(category: "Payment", rating: 5.0),
            CategoryRating(category: "Clarity", rating: 4.0),
            CategoryRating(category: "Respect", rating: 4.5)
        ]
    )
}
