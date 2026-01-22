import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class MessagingService: ObservableObject {
    static let shared = MessagingService()

    private let db = Firestore.firestore()

    @Published var conversations: [Conversation] = []
    @Published var activeConversationMessages: [Message] = []
    @Published var isLoading = false

    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?

    deinit {
        conversationsListener?.remove()
        messagesListener?.remove()
    }

    // MARK: - Conversations

    func listenToConversations(for userId: String) {
        conversationsListener?.remove()

        conversationsListener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                self?.conversations = documents.compactMap { try? $0.data(as: Conversation.self) }
            }
    }

    func stopListeningToConversations() {
        conversationsListener?.remove()
        conversationsListener = nil
    }

    func getOrCreateConversation(with participantId: String, currentUserId: String, projectId: String? = nil) async throws -> Conversation {
        // Check if conversation already exists
        let existingSnapshot = try await db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments()

        let existing = existingSnapshot.documents
            .compactMap { try? $0.data(as: Conversation.self) }
            .first { $0.participants.contains(participantId) && $0.participants.contains(currentUserId) }

        if let existing = existing {
            return existing
        }

        // Create new conversation
        let conversation = Conversation(
            participants: [currentUserId, participantId],
            createdAt: Date(),
            isActive: true,
            projectId: projectId
        )

        let docRef = try db.collection("conversations").addDocument(from: conversation)
        var newConversation = conversation
        newConversation.id = docRef.documentID
        return newConversation
    }

    func archiveConversation(id: String) async throws {
        try await db.collection("conversations").document(id).updateData([
            "isActive": false
        ])
    }

    // MARK: - Messages

    func listenToMessages(in conversationId: String) {
        messagesListener?.remove()

        messagesListener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                self?.activeConversationMessages = documents.compactMap { try? $0.data(as: Message.self) }
            }
    }

    func stopListeningToMessages() {
        messagesListener?.remove()
        messagesListener = nil
        activeConversationMessages = []
    }

    func sendMessage(
        in conversationId: String,
        senderId: String,
        content: String,
        messageType: MessageType = .text,
        attachments: [String] = []
    ) async throws {
        let message = Message(
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            messageType: messageType,
            attachments: attachments,
            timestamp: Date(),
            isRead: false
        )

        // Add message to subcollection
        _ = try db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .addDocument(from: message)

        // Update conversation metadata
        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": content,
            "lastMessageTimestamp": Timestamp(date: Date()),
            "lastMessageSenderId": senderId
        ])

        // Increment unread count for other participants
        let conversation = try await db.collection("conversations").document(conversationId).getDocument()
        if let data = conversation.data(),
           let participants = data["participants"] as? [String] {
            for participantId in participants where participantId != senderId {
                let currentUnread = (data["unreadCount"] as? [String: Int])?[participantId] ?? 0
                try await db.collection("conversations").document(conversationId).updateData([
                    "unreadCount.\(participantId)": currentUnread + 1
                ])
            }
        }
    }

    func markMessagesAsRead(in conversationId: String, for userId: String) async throws {
        // Reset unread count for user
        try await db.collection("conversations").document(conversationId).updateData([
            "unreadCount.\(userId)": 0
        ])

        // Mark individual messages as read
        let unreadMessages = try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .whereField("isRead", isEqualTo: false)
            .whereField("senderId", isNotEqualTo: userId)
            .getDocuments()

        let batch = db.batch()
        for doc in unreadMessages.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    // MARK: - Quote & Milestone Messages

    func sendQuoteMessage(
        in conversationId: String,
        senderId: String,
        description: String,
        amount: String
    ) async throws {
        let message = Message(
            conversationId: conversationId,
            senderId: senderId,
            content: "Quote: \(description)",
            messageType: .quote,
            quoteData: QuoteData(description: description, amount: amount)
        )

        _ = try db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .addDocument(from: message)

        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": "Sent a quote",
            "lastMessageTimestamp": Timestamp(date: Date()),
            "lastMessageSenderId": senderId
        ])
    }

    func sendMilestoneMessage(
        in conversationId: String,
        senderId: String,
        title: String,
        amount: String?
    ) async throws {
        let message = Message(
            conversationId: conversationId,
            senderId: senderId,
            content: "Milestone: \(title)",
            messageType: .milestone,
            milestoneData: MilestoneData(title: title, amount: amount)
        )

        _ = try db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .addDocument(from: message)

        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": "Created a milestone",
            "lastMessageTimestamp": Timestamp(date: Date()),
            "lastMessageSenderId": senderId
        ])
    }

    // MARK: - Typing Indicators

    func setTypingStatus(in conversationId: String, userId: String, isTyping: Bool) async throws {
        try await db.collection("conversations").document(conversationId).updateData([
            "typing.\(userId)": isTyping
        ])
    }

    // MARK: - Total Unread Count

    func getTotalUnreadCount(for userId: String) async throws -> Int {
        let snapshot = try await db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        var total = 0
        for doc in snapshot.documents {
            if let unreadCount = doc.data()["unreadCount"] as? [String: Int],
               let count = unreadCount[userId] {
                total += count
            }
        }
        return total
    }
}
