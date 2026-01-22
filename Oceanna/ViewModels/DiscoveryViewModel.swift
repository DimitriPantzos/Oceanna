import Foundation
import Combine

@MainActor
class DiscoveryViewModel: ObservableObject {
    private let firestoreService = FirestoreService.shared
    private let connectionService = ConnectionService.shared

    @Published var users: [User] = []
    @Published var opportunities: [FeedPost] = []
    @Published var opportunityAuthors: [String: User] = [:]
    @Published var currentIndex = 0
    @Published var isLoading = true
    @Published var errorMessage: String?

    func loadContent(for userId: String, isHireable: Bool) async {
        isLoading = true
        currentIndex = 0
        errorMessage = nil

        do {
            if isHireable {
                opportunities = try await firestoreService.fetchOpportunities()
                let authorIds = Set(opportunities.map { $0.authorId })
                let authors = try await firestoreService.fetchUsers(ids: Array(authorIds))
                opportunityAuthors = Dictionary(uniqueKeysWithValues: authors.compactMap { user in
                    guard let id = user.id else { return nil }
                    return (id, user)
                })
            } else {
                users = try await firestoreService.fetchHireableUsers(excluding: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func sendConnectionRequest(to targetUserId: String, from currentUserId: String) async {
        do {
            try await connectionService.sendConnectionRequest(to: targetUserId, from: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyToOpportunity(postId: String, userId: String) async {
        do {
            try await firestoreService.applyToOpportunity(postId: postId, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func nextCard() {
        currentIndex += 1
    }

    func refresh() {
        currentIndex = 0
    }
}
