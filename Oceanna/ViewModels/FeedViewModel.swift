import Foundation
import UIKit

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [FeedPost] = []
    @Published var userPosts: [FeedPost] = []
    @Published var isLoading = false
    @Published var isPosting = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private let storageService = StorageService.shared

    // MARK: - Load Posts

    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }

        do {
            posts = try await firestoreService.getFeedPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadUserPosts(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            userPosts = try await firestoreService.getFeedPosts(forUserId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshFeed() async {
        await loadFeed()
    }

    // MARK: - Create Post

    func createPost(
        authorId: String,
        content: String,
        postType: FeedPost.PostType,
        images: [UIImage] = [],
        tags: [String] = [],
        locationName: String? = nil,
        visibility: FeedPost.Visibility = .publicPost,
        collaborationRequest: FeedPost.CollaborationRequest? = nil
    ) async {
        isPosting = true
        defer { isPosting = false }

        do {
            var mediaUrls: [String] = []

            // Upload images if any
            if !images.isEmpty {
                let postId = UUID().uuidString
                for image in images {
                    let url = try await storageService.uploadPostMedia(
                        image: image,
                        userId: authorId,
                        postId: postId
                    )
                    mediaUrls.append(url)
                }
            }

            let post = FeedPost(
                authorId: authorId,
                content: content,
                postType: postType,
                mediaUrls: mediaUrls,
                tags: tags,
                locationName: locationName,
                visibility: visibility,
                collaborationRequest: collaborationRequest
            )

            let postId = try await firestoreService.createPost(post)
            var newPost = post
            newPost.id = postId

            // Add to local feed
            posts.insert(newPost, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createCollaborationRequest(
        authorId: String,
        title: String,
        description: String,
        rolesNeeded: [String],
        isPaid: Bool,
        deadline: Date?,
        tags: [String] = [],
        locationName: String? = nil
    ) async {
        let collabRequest = FeedPost.CollaborationRequest(
            title: title,
            description: description,
            rolesNeeded: rolesNeeded,
            isPaid: isPaid,
            deadline: deadline,
            applicants: []
        )

        await createPost(
            authorId: authorId,
            content: "Looking for collaborators: \(title)",
            postType: .collaborationRequest,
            tags: tags,
            locationName: locationName,
            collaborationRequest: collabRequest
        )
    }

    // MARK: - Interactions

    func likePost(_ post: FeedPost, userId: String) async {
        guard let postId = post.id else { return }

        do {
            if post.likes.contains(userId) {
                try await firestoreService.unlikePost(postId: postId, userId: userId)
                if let index = posts.firstIndex(where: { $0.id == postId }) {
                    posts[index].likes.removeAll { $0 == userId }
                }
            } else {
                try await firestoreService.likePost(postId: postId, userId: userId)
                if let index = posts.firstIndex(where: { $0.id == postId }) {
                    posts[index].likes.append(userId)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isLiked(_ post: FeedPost, by userId: String) -> Bool {
        post.likes.contains(userId)
    }

    // MARK: - Filters

    @Published var selectedPostType: FeedPost.PostType?
    @Published var selectedTags: [String] = []

    var filteredPosts: [FeedPost] {
        var filtered = posts

        if let postType = selectedPostType {
            filtered = filtered.filter { $0.postType == postType }
        }

        if !selectedTags.isEmpty {
            filtered = filtered.filter { post in
                !Set(post.tags).isDisjoint(with: Set(selectedTags))
            }
        }

        return filtered
    }

    func filterByType(_ type: FeedPost.PostType?) {
        selectedPostType = type
    }

    func filterByTags(_ tags: [String]) {
        selectedTags = tags
    }

    func clearFilters() {
        selectedPostType = nil
        selectedTags = []
    }
}
