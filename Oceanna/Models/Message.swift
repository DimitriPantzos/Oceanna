import Foundation
import FirebaseFirestore

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case quote = "quote"
    case proposal = "proposal"
    case milestone = "milestone"
    case completion = "completion"
}

enum MilestoneStatus: String, Codable {
    case pending = "pending"
    case completed = "completed"
}

struct MilestoneData: Codable {
    var title: String
    var amount: String?
    var status: MilestoneStatus

    init(title: String, amount: String? = nil, status: MilestoneStatus = .pending) {
        self.title = title
        self.amount = amount
        self.status = status
    }
}

struct QuoteData: Codable {
    var description: String
    var amount: String
    var validUntil: Date?

    init(description: String, amount: String, validUntil: Date? = nil) {
        self.description = description
        self.amount = amount
        self.validUntil = validUntil
    }
}

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var content: String
    var messageType: MessageType
    var attachments: [String]
    var quoteData: QuoteData?
    var milestoneData: MilestoneData?
    var createdAt: Date

    init(
        id: String? = nil,
        conversationId: String,
        senderId: String,
        content: String,
        messageType: MessageType = .text,
        attachments: [String] = [],
        quoteData: QuoteData? = nil,
        milestoneData: MilestoneData? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.messageType = messageType
        self.attachments = attachments
        self.quoteData = quoteData
        self.milestoneData = milestoneData
        self.createdAt = createdAt
    }
}

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participantIds: [String]
    var projectReference: String?
    var lastMessage: String?
    var lastMessageAt: Date?
    var unreadCounts: [String: Int]
    var isCompleted: Bool
    var completionConfirmedBy: [String]
    var createdAt: Date

    init(
        id: String? = nil,
        participantIds: [String],
        projectReference: String? = nil,
        lastMessage: String? = nil,
        lastMessageAt: Date? = nil,
        unreadCounts: [String: Int] = [:],
        isCompleted: Bool = false,
        completionConfirmedBy: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.participantIds = participantIds
        self.projectReference = projectReference
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCounts = unreadCounts
        self.isCompleted = isCompleted
        self.completionConfirmedBy = completionConfirmedBy
        self.createdAt = createdAt
    }

    func otherParticipantId(currentUserId: String) -> String? {
        participantIds.first { $0 != currentUserId }
    }

    func unreadCount(for userId: String) -> Int {
        unreadCounts[userId] ?? 0
    }

    var canLeaveReview: Bool {
        completionConfirmedBy.count == 2
    }
}

extension Message {
    static let example = Message(
        id: "msg1",
        conversationId: "conv1",
        senderId: "user1",
        content: "Hey! I'd love to work on this project with you."
    )

    static let quoteExample = Message(
        id: "msg2",
        conversationId: "conv1",
        senderId: "user1",
        content: "Here's my quote for the project:",
        messageType: .quote,
        quoteData: QuoteData(description: "Brand identity package", amount: "$1,500")
    )
}

extension Conversation {
    static let example = Conversation(
        id: "conv1",
        participantIds: ["user1", "user2"],
        lastMessage: "Sounds great, let's do it!",
        lastMessageAt: Date()
    )
}
