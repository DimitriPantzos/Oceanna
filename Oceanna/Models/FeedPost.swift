import Foundation
import FirebaseFirestore

enum PostType: String, Codable, CaseIterable {
    case portfolio = "portfolio"
    case update = "update"
    case wip = "wip"
    case opportunity = "opportunity"
    case collaboration = "collaboration"
    case milestone = "milestone"
    case question = "question"

    var displayName: String {
        switch self {
        case .portfolio: return "Work"
        case .update: return "Update"
        case .wip: return "In Progress"
        case .opportunity: return "Opportunity"
        case .collaboration: return "Collab"
        case .milestone: return "Milestone"
        case .question: return "Question"
        }
    }

    var icon: String {
        switch self {
        case .portfolio: return "photo"
        case .update: return "text.bubble"
        case .wip: return "hammer"
        case .opportunity: return "briefcase"
        case .collaboration: return "person.2"
        case .milestone: return "star"
        case .question: return "questionmark.circle"
        }
    }
}

struct OpportunityDetails: Codable {
    var budget: String?
    var timeline: String?
    var locationPreference: Availability
    var skillsNeeded: [String]

    init(budget: String? = nil, timeline: String? = nil, locationPreference: Availability = .both, skillsNeeded: [String] = []) {
        self.budget = budget
        self.timeline = timeline
        self.locationPreference = locationPreference
        self.skillsNeeded = skillsNeeded
    }
}

struct FeedPost: Identifiable, Codable {
    @DocumentID var id: String?
    var authorId: String
    var postType: PostType
    var content: String
    var mediaUrls: [String]
    var tags: [String]
    var opportunityDetails: OpportunityDetails?
    var interestedUserIds: [String]
    var applicantIds: [String]
    var createdAt: Date

    init(
        id: String? = nil,
        authorId: String,
        postType: PostType,
        content: String,
        mediaUrls: [String] = [],
        tags: [String] = [],
        opportunityDetails: OpportunityDetails? = nil,
        interestedUserIds: [String] = [],
        applicantIds: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.authorId = authorId
        self.postType = postType
        self.content = content
        self.mediaUrls = mediaUrls
        self.tags = tags
        self.opportunityDetails = opportunityDetails
        self.interestedUserIds = interestedUserIds
        self.applicantIds = applicantIds
        self.createdAt = createdAt
    }

    var isOpportunity: Bool {
        postType == .opportunity
    }
}

extension FeedPost {
    static let portfolioExample = FeedPost(
        id: "post1",
        authorId: "user123",
        postType: .portfolio,
        content: "Just wrapped up this brand identity project. Really happy with how the color palette came together.",
        mediaUrls: ["https://example.com/work1.jpg"],
        tags: ["Branding", "Identity"]
    )

    static let opportunityExample = FeedPost(
        id: "post2",
        authorId: "user456",
        postType: .opportunity,
        content: "Looking for a photographer for a product shoot this Saturday. Natural light, minimal aesthetic.",
        opportunityDetails: OpportunityDetails(
            budget: "$500-800",
            timeline: "This weekend",
            locationPreference: .inPerson,
            skillsNeeded: ["Product Photography", "Lighting"]
        )
    )
}
