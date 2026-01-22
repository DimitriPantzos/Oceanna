import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    private let messagingService = MessagingService.shared

    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSending = false

    private var cancellables = Set<AnyCancellable>()

    let conversationId: String
    let currentUserId: String

    init(conversationId: String, currentUserId: String) {
        self.conversationId = conversationId
        self.currentUserId = currentUserId

        messagingService.$activeConversationMessages
            .assign(to: &$messages)
    }

    func startListening() {
        messagingService.listenToMessages(in: conversationId)

        Task {
            try? await messagingService.markMessagesAsRead(in: conversationId, for: currentUserId)
        }
    }

    func stopListening() {
        messagingService.stopListeningToMessages()
    }

    func sendMessage(content: String, type: MessageType = .text) async {
        guard !content.isEmpty else { return }

        isSending = true
        do {
            try await messagingService.sendMessage(
                in: conversationId,
                senderId: currentUserId,
                content: content,
                messageType: type
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    func sendQuote(description: String, amount: String) async {
        isSending = true
        do {
            try await messagingService.sendQuoteMessage(
                in: conversationId,
                senderId: currentUserId,
                description: description,
                amount: amount
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    func sendMilestone(title: String, amount: String?) async {
        isSending = true
        do {
            try await messagingService.sendMilestoneMessage(
                in: conversationId,
                senderId: currentUserId,
                title: title,
                amount: amount
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    func setTyping(_ isTyping: Bool) async {
        try? await messagingService.setTypingStatus(
            in: conversationId,
            userId: currentUserId,
            isTyping: isTyping
        )
    }

    func markComplete() async {
        isSending = true
        do {
            try await messagingService.sendMessage(
                in: conversationId,
                senderId: currentUserId,
                content: "Requested project completion",
                messageType: .completion
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }
}
