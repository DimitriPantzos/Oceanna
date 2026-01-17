import Foundation
import FirebaseFirestore

@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    // MARK: - Users

    func fetchUser(id: String) async throws -> User? {
        let document = try await db.collection("users").document(id).getDocument()
        return try document.data(as: User.self)
    }

    func fetchUsers(ids: [String]) async throws -> [User] {
        guard !ids.isEmpty else { return [] }

        // Firestore limits 'in' queries to 10 items
        var allUsers: [User] = []
        for chunk in ids.chunked(into: 10) {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
            allUsers.append(contentsOf: users)
        }
        return allUsers
    }

    func fetchApprovedUsers(excluding userId: String, limit: Int = 50) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .whereField("approvalStatus", isEqualTo: ApprovalStatus.approved.rawValue)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: User.self) }
            .filter { $0.id != userId }
    }

    func fetchHireableUsers(excluding userId: String, limit: Int = 50) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .whereField("approvalStatus", isEqualTo: ApprovalStatus.approved.rawValue)
            .whereField("isHireable", isEqualTo: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: User.self) }
            .filter { $0.id != userId }
    }

    // MARK: - Portfolio

    func fetchPortfolio(for userId: String) async throws -> [PortfolioItem] {
        let snapshot = try await db.collection("portfolios")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: PortfolioItem.self) }
    }

    func addPortfolioItem(_ item: PortfolioItem) async throws {
        let docRef = db.collection("portfolios").document()
        var itemWithId = item
        itemWithId.id = docRef.documentID
        try docRef.setData(from: itemWithId)
    }

    func deletePortfolioItem(id: String) async throws {
        try await db.collection("portfolios").document(id).delete()
    }

    // MARK: - Posts

    func fetchPosts(for userIds: [String], limit: Int = 50) async throws -> [FeedPost] {
        guard !userIds.isEmpty else { return [] }

        var allPosts: [FeedPost] = []
        for chunk in userIds.chunked(into: 10) {
            let snapshot = try await db.collection("posts")
                .whereField("authorId", in: chunk)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()

            let posts = snapshot.documents.compactMap { try? $0.data(as: FeedPost.self) }
            allPosts.append(contentsOf: posts)
        }

        return allPosts.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchOpportunities(limit: Int = 50) async throws -> [FeedPost] {
        let snapshot = try await db.collection("posts")
            .whereField("postType", isEqualTo: PostType.opportunity.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: FeedPost.self) }
    }

    func createPost(_ post: FeedPost) async throws -> FeedPost {
        let docRef = db.collection("posts").document()
        var postWithId = post
        postWithId.id = docRef.documentID
        try docRef.setData(from: postWithId)
        return postWithId
    }

    func expressInterest(postId: String, userId: String) async throws {
        try await db.collection("posts").document(postId).updateData([
            "interestedUserIds": FieldValue.arrayUnion([userId])
        ])
    }

    func applyToOpportunity(postId: String, userId: String) async throws {
        try await db.collection("posts").document(postId).updateData([
            "applicantIds": FieldValue.arrayUnion([userId])
        ])
    }

    // MARK: - Reviews

    func fetchReviews(for userId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("revieweeId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Review.self) }
    }

    func createReview(_ review: Review) async throws {
        let docRef = db.collection("reviews").document()
        var reviewWithId = review
        reviewWithId.id = docRef.documentID
        try docRef.setData(from: reviewWithId)
    }

    func hasReviewed(conversationId: String, reviewerId: String) async throws -> Bool {
        let snapshot = try await db.collection("reviews")
            .whereField("conversationId", isEqualTo: conversationId)
            .whereField("reviewerId", isEqualTo: reviewerId)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
