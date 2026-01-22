import Foundation
import Combine

@MainActor
class MessagesViewModel: ObservableObject {
    private let messagingService = MessagingService.shared
    private let firestoreService = FirestoreService.shared
    private let connectionService = ConnectionService.shared

    @Published var conversations: [Conversation] = []
    @Published var connectionRequests: [Connection] = []
    @Published var participantProfiles: [String: User] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        messagingService.$conversations
            .assign(to: &$conversations)

        connectionService.$pendingRequests
            .assign(to: &$connectionRequests)
    }

    func startListening(for userId: String) {
        messagingService.listenToConversations(for: userId)

        Task {
            await loadConnectionRequests(for: userId)
            await loadParticipantProfiles(for: userId)
        }
    }

    func stopListening() {
        messagingService.stopListeningToConversations()
    }

    func loadConnectionRequests(for userId: String) async {
        await connectionService.fetchPendingRequests(for: userId)
    }

    func loadParticipantProfiles(for userId: String) async {
        await connectionService.fetchConnections(for: userId)

        var allUserIds = Set(connectionRequests.map { $0.requesterId })
        allUserIds.formUnion(connectionService.connectedUserIds)

        // Add participants from conversations
        for conversation in conversations {
            allUserIds.formUnion(conversation.participants.filter { $0 != userId })
        }

        guard !allUserIds.isEmpty else { return }

        do {
            let users = try await firestoreService.fetchUsers(ids: Array(allUserIds))
            participantProfiles = Dictionary(uniqueKeysWithValues: users.compactMap { user in
                guard let id = user.id else { return nil }
                return (id, user)
            })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadParticipantProfile(userId: String) async {
        guard participantProfiles[userId] == nil else { return }

        do {
            if let user = try await firestoreService.fetchUser(id: userId) {
                participantProfiles[userId] = user
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }

    func acceptConnection(_ connection: Connection, currentUserId: String) async {
        do {
            try await connectionService.acceptConnection(connection)
            await loadConnectionRequests(for: currentUserId)
            await loadParticipantProfiles(for: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineConnection(_ connection: Connection, currentUserId: String) async {
        do {
            try await connectionService.ignoreConnection(connection)
            await loadConnectionRequests(for: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshData(for userId: String) async {
        isLoading = true
        await loadConnectionRequests(for: userId)
        await loadParticipantProfiles(for: userId)
        isLoading = false
    }
}
