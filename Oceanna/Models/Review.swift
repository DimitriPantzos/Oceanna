import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var reviewerId: String
    var revieweeId: String
    var conversationId: String
    var qualityRating: Int
    var communicationRating: Int
    var timelinessRating: Int
    var content: String?
    var createdAt: Date

    var averageRating: Double {
        Double(qualityRating + communicationRating + timelinessRating) / 3.0
    }

    init(
        id: String? = nil,
        reviewerId: String,
        revieweeId: String,
        conversationId: String,
        qualityRating: Int,
        communicationRating: Int,
        timelinessRating: Int,
        content: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reviewerId = reviewerId
        self.revieweeId = revieweeId
        self.conversationId = conversationId
        self.qualityRating = min(5, max(1, qualityRating))
        self.communicationRating = min(5, max(1, communicationRating))
        self.timelinessRating = min(5, max(1, timelinessRating))
        self.content = content
        self.createdAt = createdAt
    }
}

extension Review {
    static let example = Review(
        id: "review1",
        reviewerId: "user1",
        revieweeId: "user2",
        conversationId: "conv1",
        qualityRating: 5,
        communicationRating: 5,
        timelinessRating: 4,
        content: "Amazing work! Sarah delivered exactly what we discussed and was super responsive throughout."
    )
}
