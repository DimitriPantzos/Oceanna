import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showCreatePost = false
    @State private var selectedFilter: FeedPost.PostType?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                                viewModel.filterByType(nil)
                            }

                            ForEach(FeedPost.PostType.allCases, id: \.self) { type in
                                FilterChip(title: type.rawValue, isSelected: selectedFilter == type) {
                                    selectedFilter = type
                                    viewModel.filterByType(type)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    // Posts
                    ForEach(viewModel.filteredPosts) { post in
                        FeedPostCard(post: post, viewModel: viewModel)
                            .padding(.horizontal)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshFeed()
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadFeed()
            }
            .overlay {
                if !viewModel.isLoading && viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        "No Posts Yet",
                        systemImage: "square.stack",
                        description: Text("Be the first to share something with the community!")
                    )
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct FeedPostCard: View {
    let post: FeedPost
    @ObservedObject var viewModel: FeedViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var authorUser: User?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(authorUser?.initials ?? "?")
                            .font(.headline)
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(authorUser?.displayName ?? "User")
                        .font(.headline)

                    HStack(spacing: 4) {
                        Text(post.postType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)

                        if let location = post.locationName {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(formatDate(post.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Menu {
                    Button("Share", systemImage: "square.and.arrow.up") { }
                    Button("Report", systemImage: "flag") { }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }

            // Content
            Text(post.content)
                .font(.body)

            // Collaboration Request
            if let collab = post.collaborationRequest {
                CollaborationRequestCard(request: collab)
            }

            // Media
            if !post.mediaUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.mediaUrls, id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 200, height: 150)
                            .cornerRadius(12)
                        }
                    }
                }
            }

            // Tags
            if !post.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Divider()

            // Actions
            HStack(spacing: 24) {
                Button {
                    if let userId = authViewModel.currentUser?.id {
                        Task {
                            await viewModel.likePost(post, userId: userId)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .secondary)
                        Text("\(post.likes.count)")
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    // Comments
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(post.commentCount)")
                    }
                    .foregroundColor(.secondary)
                }

                Button {
                    // Share
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .task {
            authorUser = try? await FirestoreService.shared.getUser(id: post.authorId)
        }
    }

    var isLiked: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return post.likes.contains(userId)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CollaborationRequestCard: View {
    let request: FeedPost.CollaborationRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text(request.title)
                    .font(.headline)

                Spacer()

                if request.isPaid {
                    Text("Paid")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }

            Text(request.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Looking for:")
                .font(.caption)
                .foregroundColor(.secondary)

            FlowLayout(spacing: 6) {
                ForEach(request.rolesNeeded, id: \.self) { role in
                    Text(role)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }

            if let deadline = request.deadline {
                HStack {
                    Image(systemName: "calendar")
                    Text("Apply by \(deadline.formatted(date: .abbreviated, time: .omitted))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Button("Apply to Collaborate") {
                // Apply action
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    FeedView()
        .environmentObject(AuthViewModel())
}
