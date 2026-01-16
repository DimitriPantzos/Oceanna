import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    // MARK: - Freelancer Profiles

    func getFreelancerProfile(userId: String) async throws -> FreelancerProfile? {
        let document = try await db.collection("freelancerProfiles").document(userId).getDocument()
        return try document.data(as: FreelancerProfile.self)
    }

    func updateFreelancerProfile(_ profile: FreelancerProfile) async throws {
        guard let id = profile.id else { return }
        try db.collection("freelancerProfiles").document(id).setData(from: profile, merge: true)
    }

    func getNearbyFreelancers(center: GeoPoint, radiusMiles: Double, category: String? = nil, limit: Int = 50) async throws -> [FreelancerProfile] {
        // Note: For production, use GeoFirestore or a geohashing solution
        // This is a simplified implementation
        var query: Query = db.collection("freelancerProfiles")

        if let category = category {
            query = query.whereField("categories", arrayContains: category)
        }

        query = query.limit(to: limit)

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FreelancerProfile.self) }
    }

    func searchFreelancers(skills: [String]? = nil, categories: [String]? = nil, minRating: Double? = nil) async throws -> [FreelancerProfile] {
        var query: Query = db.collection("freelancerProfiles")

        if let skills = skills, !skills.isEmpty {
            query = query.whereField("skills", arrayContainsAny: skills)
        }

        if let minRating = minRating {
            query = query.whereField("rating", isGreaterThanOrEqualTo: minRating)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FreelancerProfile.self) }
    }

    // MARK: - Client Profiles

    func getClientProfile(userId: String) async throws -> ClientProfile? {
        let document = try await db.collection("clientProfiles").document(userId).getDocument()
        return try document.data(as: ClientProfile.self)
    }

    func updateClientProfile(_ profile: ClientProfile) async throws {
        guard let id = profile.id else { return }
        try db.collection("clientProfiles").document(id).setData(from: profile, merge: true)
    }

    // MARK: - Projects

    func createProject(_ project: Project) async throws -> String {
        let docRef = try db.collection("projects").addDocument(from: project)
        return docRef.documentID
    }

    func getProject(id: String) async throws -> Project? {
        let document = try await db.collection("projects").document(id).getDocument()
        return try document.data(as: Project.self)
    }

    func updateProject(_ project: Project) async throws {
        guard let id = project.id else { return }
        try db.collection("projects").document(id).setData(from: project, merge: true)
    }

    func getOpenProjects(near location: GeoPoint? = nil, category: String? = nil, limit: Int = 20) async throws -> [Project] {
        var query: Query = db.collection("projects")
            .whereField("status", isEqualTo: Project.ProjectStatus.open.rawValue)
            .order(by: "createdAt", descending: true)

        if let category = category {
            query = query.whereField("category", isEqualTo: category)
        }

        query = query.limit(to: limit)

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Project.self) }
    }

    func getClientProjects(clientId: String) async throws -> [Project] {
        let snapshot = try await db.collection("projects")
            .whereField("clientId", isEqualTo: clientId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Project.self) }
    }

    func applyToProject(projectId: String, freelancerId: String) async throws {
        try await db.collection("projects").document(projectId).updateData([
            "applicants": FieldValue.arrayUnion([freelancerId])
        ])
    }

    // MARK: - Reviews

    func createReview(_ review: Review) async throws {
        _ = try db.collection("reviews").addDocument(from: review)

        // Update the reviewee's rating
        try await updateUserRating(userId: review.revieweeId, newRating: review.rating)
    }

    func getReviews(for userId: String, limit: Int = 20) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("revieweeId", isEqualTo: userId)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Review.self) }
    }

    private func updateUserRating(userId: String, newRating: Double) async throws {
        // Fetch all reviews for recalculation
        let reviews = try await getReviews(for: userId, limit: 1000)
        let totalRating = reviews.reduce(0) { $0 + $1.rating }
        let averageRating = reviews.isEmpty ? 0 : totalRating / Double(reviews.count)

        // Update freelancer or client profile
        let freelancerDoc = db.collection("freelancerProfiles").document(userId)
        let clientDoc = db.collection("clientProfiles").document(userId)

        let freelancerSnapshot = try await freelancerDoc.getDocument()
        if freelancerSnapshot.exists {
            try await freelancerDoc.updateData([
                "rating": averageRating,
                "reviewCount": reviews.count
            ])
        }

        let clientSnapshot = try await clientDoc.getDocument()
        if clientSnapshot.exists {
            try await clientDoc.updateData([
                "rating": averageRating,
                "reviewCount": reviews.count
            ])
        }
    }

    // MARK: - Feed Posts

    func createPost(_ post: FeedPost) async throws -> String {
        let docRef = try db.collection("posts").addDocument(from: post)
        return docRef.documentID
    }

    func getFeedPosts(forUserId userId: String? = nil, limit: Int = 20) async throws -> [FeedPost] {
        var query: Query = db.collection("posts")
            .order(by: "createdAt", descending: true)

        if let userId = userId {
            query = query.whereField("authorId", isEqualTo: userId)
        }

        query = query.limit(to: limit)

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FeedPost.self) }
    }

    func likePost(postId: String, userId: String) async throws {
        try await db.collection("posts").document(postId).updateData([
            "likes": FieldValue.arrayUnion([userId])
        ])
    }

    func unlikePost(postId: String, userId: String) async throws {
        try await db.collection("posts").document(postId).updateData([
            "likes": FieldValue.arrayRemove([userId])
        ])
    }

    // MARK: - Creative Circles

    func getCreativeCircles(near location: GeoPoint, radiusMiles: Double) async throws -> [CreativeCircle] {
        // Simplified - in production use geohashing
        let snapshot = try await db.collection("creativeCircles")
            .whereField("isPublic", isEqualTo: true)
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: CreativeCircle.self) }
    }

    func joinCircle(circleId: String, userId: String) async throws {
        try await db.collection("creativeCircles").document(circleId).updateData([
            "members": FieldValue.arrayUnion([userId])
        ])
    }

    func leaveCircle(circleId: String, userId: String) async throws {
        try await db.collection("creativeCircles").document(circleId).updateData([
            "members": FieldValue.arrayRemove([userId])
        ])
    }

    // MARK: - User Lookup

    func getUser(id: String) async throws -> User? {
        let document = try await db.collection("users").document(id).getDocument()
        return try document.data(as: User.self)
    }

    func getUsers(ids: [String]) async throws -> [User] {
        guard !ids.isEmpty else { return [] }

        let snapshot = try await db.collection("users")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
}
