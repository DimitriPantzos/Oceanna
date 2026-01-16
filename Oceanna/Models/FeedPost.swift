import Foundation
import FirebaseFirestore

struct FeedPost: Identifiable, Codable {
    @DocumentID var id: String?
    var authorId: String
    var content: String
    var postType: PostType
    var mediaUrls: [String]
    var createdAt: Date
    var updatedAt: Date
    var likes: [String] // User IDs who liked
    var commentCount: Int
    var shareCount: Int
    var tags: [String]
    var location: GeoPoint?
    var locationName: String?
    var visibility: Visibility
    var linkedProjectId: String?
    var collaborationRequest: CollaborationRequest?

    enum PostType: String, Codable, CaseIterable {
        case update = "Update"
        case portfolio = "Portfolio"
        case workInProgress = "Work in Progress"
        case collaborationRequest = "Collab Request"
        case opportunity = "Opportunity"
        case event = "Event"
        case milestone = "Milestone"
    }

    enum Visibility: String, Codable, CaseIterable {
        case publicPost = "Public"
        case connectionsOnly = "Connections Only"
        case localOnly = "Local Only"
    }

    struct CollaborationRequest: Codable {
        var title: String
        var description: String
        var rolesNeeded: [String]
        var isPaid: Bool
        var deadline: Date?
        var applicants: [String]
    }

    init(
        id: String? = nil,
        authorId: String,
        content: String,
        postType: PostType = .update,
        mediaUrls: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        likes: [String] = [],
        commentCount: Int = 0,
        shareCount: Int = 0,
        tags: [String] = [],
        location: GeoPoint? = nil,
        locationName: String? = nil,
        visibility: Visibility = .publicPost,
        linkedProjectId: String? = nil,
        collaborationRequest: CollaborationRequest? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.content = content
        self.postType = postType
        self.mediaUrls = mediaUrls
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likes = likes
        self.commentCount = commentCount
        self.shareCount = shareCount
        self.tags = tags
        self.location = location
        self.locationName = locationName
        self.visibility = visibility
        self.linkedProjectId = linkedProjectId
        self.collaborationRequest = collaborationRequest
    }
}

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var postId: String
    var authorId: String
    var content: String
    var createdAt: Date
    var likes: [String]
    var parentCommentId: String? // For replies

    init(
        id: String? = nil,
        postId: String,
        authorId: String,
        content: String,
        createdAt: Date = Date(),
        likes: [String] = [],
        parentCommentId: String? = nil
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.content = content
        self.createdAt = createdAt
        self.likes = likes
        self.parentCommentId = parentCommentId
    }
}

extension FeedPost {
    static let example = FeedPost(
        id: "post123",
        authorId: "user123",
        content: "Just finished this brand identity project for a local bakery! Loved working with natural, warm colors. What do you think?",
        postType: .portfolio,
        mediaUrls: ["https://example.com/image1.jpg"],
        likes: ["user456", "user789"],
        commentCount: 5,
        tags: ["branding", "design", "logo"],
        locationName: "Austin, TX"
    )

    static let collabExample = FeedPost(
        id: "post456",
        authorId: "user123",
        content: "Looking for collaborators for an upcoming music video shoot!",
        postType: .collaborationRequest,
        tags: ["video", "music", "collaboration"],
        locationName: "Los Angeles, CA",
        collaborationRequest: CollaborationRequest(
            title: "Music Video Shoot",
            description: "Need a cinematographer and editor for a 3-day shoot",
            rolesNeeded: ["Cinematographer", "Video Editor", "Colorist"],
            isPaid: true,
            deadline: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
            applicants: []
        )
    )
}
