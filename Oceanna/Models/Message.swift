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
    var timestamp: Date
    var isRead: Bool

    init(
        id: String? = nil,
        conversationId: String,
        senderId: String,
        content: String,
        messageType: MessageType = .text,
        attachments: [String] = [],
        quoteData: QuoteData? = nil,
        milestoneData: MilestoneData? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.messageType = messageType
        self.attachments = attachments
        self.quoteData = quoteData
        self.milestoneData = milestoneData
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String]
    var projectId: String?
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var lastMessageSenderId: String?
    var unreadCount: [String: Int]
    var isActive: Bool
    var isCompleted: Bool
    var completionConfirmedBy: [String]
    var createdAt: Date

    init(
        id: String? = nil,
        participants: [String],
        projectId: String? = nil,
        lastMessage: String? = nil,
        lastMessageTimestamp: Date? = nil,
        lastMessageSenderId: String? = nil,
        unreadCount: [String: Int] = [:],
        isActive: Bool = true,
        isCompleted: Bool = false,
        completionConfirmedBy: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.participants = participants
        self.projectId = projectId
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCount = unreadCount
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.completionConfirmedBy = completionConfirmedBy
        self.createdAt = createdAt
    }

    func otherParticipantId(currentUserId: String) -> String? {
        participants.first { $0 != currentUserId }
    }

    func unreadCountFor(_ userId: String) -> Int {
        unreadCount[userId] ?? 0
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
        content: "Hey! I'd love to work on this project with you.",
        timestamp: Date()
    )

    static let quoteExample = Message(
        id: "msg2",
        conversationId: "conv1",
        senderId: "user1",
        content: "Here's my quote for the project:",
        messageType: .quote,
        quoteData: QuoteData(description: "Brand identity package", amount: "$1,500"),
        timestamp: Date()
    )
}

extension Conversation {
    static let example = Conversation(
        id: "conv1",
        participants: ["user1", "user2"],
        lastMessage: "Sounds great, let's do it!",
        lastMessageTimestamp: Date()
    )
}
