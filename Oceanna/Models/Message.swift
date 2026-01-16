import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String] // User IDs
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var lastMessageSenderId: String?
    var unreadCount: [String: Int] // userId: count
    var createdAt: Date
    var isActive: Bool
    var projectId: String? // Optional link to a project

    init(
        id: String? = nil,
        participants: [String],
        lastMessage: String? = nil,
        lastMessageTimestamp: Date? = nil,
        lastMessageSenderId: String? = nil,
        unreadCount: [String: Int] = [:],
        createdAt: Date = Date(),
        isActive: Bool = true,
        projectId: String? = nil
    ) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCount = unreadCount
        self.createdAt = createdAt
        self.isActive = isActive
        self.projectId = projectId
    }
}

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var content: String
    var messageType: MessageType
    var timestamp: Date
    var isRead: Bool
    var attachments: [Attachment]
    var replyToMessageId: String?

    enum MessageType: String, Codable {
        case text
        case image
        case file
        case projectProposal
        case systemMessage
    }

    struct Attachment: Identifiable, Codable {
        var id: String = UUID().uuidString
        var url: String
        var type: AttachmentType
        var name: String?
        var size: Int?

        enum AttachmentType: String, Codable {
            case image
            case video
            case pdf
            case document
            case other
        }
    }

    init(
        id: String? = nil,
        conversationId: String,
        senderId: String,
        content: String,
        messageType: MessageType = .text,
        timestamp: Date = Date(),
        isRead: Bool = false,
        attachments: [Attachment] = [],
        replyToMessageId: String? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.messageType = messageType
        self.timestamp = timestamp
        self.isRead = isRead
        self.attachments = attachments
        self.replyToMessageId = replyToMessageId
    }
}

extension Conversation {
    static let example = Conversation(
        id: "conv123",
        participants: ["user123", "user456"],
        lastMessage: "Sounds great! Let's discuss the details.",
        lastMessageTimestamp: Date(),
        lastMessageSenderId: "user456",
        unreadCount: ["user123": 1, "user456": 0]
    )
}

extension Message {
    static let example = Message(
        id: "msg123",
        conversationId: "conv123",
        senderId: "user456",
        content: "Hi! I saw your project posting and I'd love to help. I have experience with similar work.",
        messageType: .text,
        timestamp: Date()
    )
}
