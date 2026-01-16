import Foundation
import UIKit

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var totalUnreadCount = 0

    // User cache for displaying names/avatars
    @Published var userCache: [String: User] = [:]

    private let messagingService = MessagingService.shared
    private let firestoreService = FirestoreService.shared
    private let storageService = StorageService.shared

    private var currentUserId: String?

    // MARK: - Conversations

    func startListening(for userId: String) {
        currentUserId = userId
        messagingService.listenToConversations(for: userId)

        // Observe conversation updates
        messagingService.$conversations
            .assign(to: &$conversations)

        // Load unread count
        Task {
            await updateUnreadCount()
        }
    }

    func stopListening() {
        messagingService.stopListeningToConversations()
        messagingService.stopListeningToMessages()
    }

    func loadConversationUsers() async {
        let userIds = Set(conversations.flatMap { $0.participants })
        let unknownIds = userIds.filter { userCache[$0] == nil }

        if !unknownIds.isEmpty {
            do {
                let users = try await firestoreService.getUsers(ids: Array(unknownIds))
                for user in users {
                    if let id = user.id {
                        userCache[id] = user
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func getOtherParticipant(in conversation: Conversation) -> User? {
        guard let currentUserId = currentUserId else { return nil }
        let otherId = conversation.participants.first { $0 != currentUserId }
        return otherId.flatMap { userCache[$0] }
    }

    func getUnreadCount(for conversation: Conversation) -> Int {
        guard let currentUserId = currentUserId else { return 0 }
        return conversation.unreadCount[currentUserId] ?? 0
    }

    private func updateUnreadCount() async {
        guard let userId = currentUserId else { return }
        do {
            totalUnreadCount = try await messagingService.getTotalUnreadCount(for: userId)
        } catch {
            print("Error updating unread count: \(error)")
        }
    }

    // MARK: - Messages

    func openConversation(_ conversation: Conversation) {
        guard let conversationId = conversation.id else { return }

        messagingService.listenToMessages(in: conversationId)

        messagingService.$activeConversationMessages
            .assign(to: &$messages)

        // Mark as read
        if let userId = currentUserId {
            Task {
                try? await messagingService.markMessagesAsRead(in: conversationId, for: userId)
                await updateUnreadCount()
            }
        }
    }

    func closeConversation() {
        messagingService.stopListeningToMessages()
        messages = []
    }

    func startConversation(with userId: String, projectId: String? = nil) async -> Conversation? {
        guard let currentUserId = currentUserId else { return nil }

        do {
            let conversation = try await messagingService.getOrCreateConversation(
                with: userId,
                currentUserId: currentUserId,
                projectId: projectId
            )
            return conversation
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Send Message

    func sendMessage(
        in conversationId: String,
        content: String,
        attachments: [UIImage] = []
    ) async {
        guard let senderId = currentUserId else { return }

        isSending = true
        defer { isSending = false }

        do {
            var messageAttachments: [Message.Attachment] = []

            // Upload image attachments
            for (index, image) in attachments.enumerated() {
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    let messageId = UUID().uuidString
                    let url = try await storageService.uploadMessageAttachment(
                        data: imageData,
                        conversationId: conversationId,
                        messageId: messageId,
                        filename: "image_\(index).jpg",
                        contentType: "image/jpeg"
                    )
                    messageAttachments.append(Message.Attachment(
                        url: url,
                        type: .image,
                        name: "image_\(index).jpg"
                    ))
                }
            }

            try await messagingService.sendMessage(
                in: conversationId,
                senderId: senderId,
                content: content,
                messageType: attachments.isEmpty ? .text : .image,
                attachments: messageAttachments
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Typing Indicator

    func setTyping(in conversationId: String, isTyping: Bool) {
        guard let userId = currentUserId else { return }
        Task {
            try? await messagingService.setTypingStatus(
                in: conversationId,
                userId: userId,
                isTyping: isTyping
            )
        }
    }

    // MARK: - Archive

    func archiveConversation(_ conversation: Conversation) async {
        guard let conversationId = conversation.id else { return }

        do {
            try await messagingService.archiveConversation(id: conversationId)
            conversations.removeAll { $0.id == conversationId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helper

    func isFromCurrentUser(_ message: Message) -> Bool {
        message.senderId == currentUserId
    }

    func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
