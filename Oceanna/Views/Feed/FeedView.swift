import SwiftUI

struct FeedView: View {
    @EnvironmentObject var authService: AuthService
    private let connectionService = ConnectionService.shared
    private let firestoreService = FirestoreService.shared

    @State private var posts: [FeedPost] = []
    @State private var authors: [String: User] = [:]
    @State private var isLoading = true
    @State private var showingCreatePost = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, OceannaTheme.Spacing.xxxl)
                } else if posts.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: OceannaTheme.Spacing.lg) {
                        ForEach(posts) { post in
                            if let author = authors[post.authorId] {
                                PostCard(post: post, author: author)
                            }
                        }
                    }
                    .padding(.vertical, OceannaTheme.Spacing.md)
                }
            }
            .background(OceannaTheme.Colors.background)
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePost = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(OceannaTheme.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
            }
            .refreshable {
                await loadFeed()
            }
            .task {
                await loadFeed()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: OceannaTheme.Spacing.md) {
            Image(systemName: "square.stack")
                .font(.system(size: 48))
                .foregroundColor(OceannaTheme.Colors.tertiaryText)

            Text("No posts yet")
                .font(OceannaTheme.Typography.headline)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            Text("Follow people to see their posts here")
                .font(OceannaTheme.Typography.subheadline)
                .foregroundColor(OceannaTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, OceannaTheme.Spacing.xxxl)
    }

    private func loadFeed() async {
        guard let userId = authService.userProfile?.id else { return }

        // Get connections
        await connectionService.fetchConnections(for: userId)

        // Include own posts + connected users' posts
        var userIds = Array(connectionService.connectedUserIds)
        userIds.append(userId)

        do {
            posts = try await firestoreService.fetchPosts(for: userIds)

            // Fetch authors
            let authorIds = Set(posts.map { $0.authorId })
            let users = try await firestoreService.fetchUsers(ids: Array(authorIds))
            authors = Dictionary(uniqueKeysWithValues: users.compactMap { user in
                guard let id = user.id else { return nil }
                return (id, user)
            })
        } catch {
            print("Error loading feed: \(error)")
        }

        isLoading = false
    }
}

struct PostCard: View {
    let post: FeedPost
    let author: User
    @State private var showingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
            // Header
            HStack(spacing: OceannaTheme.Spacing.sm) {
                AvatarView(url: author.avatarUrl, initials: author.initials, size: 40)

                VStack(alignment: .leading, spacing: 0) {
                    Text(author.displayName)
                        .font(OceannaTheme.Typography.headline)
                        .foregroundColor(OceannaTheme.Colors.primaryText)

                    HStack(spacing: OceannaTheme.Spacing.xxs) {
                        Text(post.postType.displayName)
                            .font(OceannaTheme.Typography.monoSmall)
                            .foregroundColor(OceannaTheme.Colors.secondaryText)

                        Text("·")
                            .foregroundColor(OceannaTheme.Colors.tertiaryText)

                        Text(post.createdAt, style: .relative)
                            .font(OceannaTheme.Typography.caption)
                            .foregroundColor(OceannaTheme.Colors.tertiaryText)
                    }
                }

                Spacer()
            }

            // Content
            Text(post.content)
                .font(OceannaTheme.Typography.body)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            // Media
            if let firstImage = post.mediaUrls.first {
                AsyncImage(url: URL(string: firstImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(OceannaTheme.Colors.secondaryBackground)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
                .cornerRadius(OceannaTheme.Radius.sm)
            }

            // Opportunity Details
            if post.isOpportunity, let details = post.opportunityDetails {
                OpportunityDetailsCard(details: details, postId: post.id ?? "")
            }

            // Tags
            if !post.tags.isEmpty {
                FlowLayout(spacing: OceannaTheme.Spacing.xxs) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(OceannaTheme.Typography.monoSmall)
                            .foregroundColor(OceannaTheme.Colors.secondaryText)
                    }
                }
            }
        }
        .padding(OceannaTheme.Spacing.md)
        .background(OceannaTheme.Colors.background)
        .overlay(
            Rectangle()
                .fill(OceannaTheme.Colors.divider)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct OpportunityDetailsCard: View {
    let details: OpportunityDetails
    let postId: String
    @EnvironmentObject var authService: AuthService
    private let firestoreService = FirestoreService.shared
    @State private var isInterested = false
    @State private var hasApplied = false

    var body: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
            HStack(spacing: OceannaTheme.Spacing.md) {
                if let budget = details.budget {
                    Label(budget, systemImage: "dollarsign.circle")
                        .font(OceannaTheme.Typography.mono)
                }

                if let timeline = details.timeline {
                    Label(timeline, systemImage: "calendar")
                        .font(OceannaTheme.Typography.mono)
                }

                Label(details.locationPreference.displayName, systemImage: "mappin")
                    .font(OceannaTheme.Typography.mono)
            }
            .foregroundColor(OceannaTheme.Colors.secondaryText)

            if !details.skillsNeeded.isEmpty {
                FlowLayout(spacing: OceannaTheme.Spacing.xxs) {
                    ForEach(details.skillsNeeded, id: \.self) { skill in
                        Text(skill)
                            .monoTag()
                    }
                }
            }

            HStack(spacing: OceannaTheme.Spacing.md) {
                Button {
                    expressInterest()
                } label: {
                    Text(isInterested ? "Interested" : "I'm Interested")
                        .frame(maxWidth: .infinity)
                }
                .oceannaButton(isPrimary: false)
                .disabled(isInterested)

                Button {
                    apply()
                } label: {
                    Text(hasApplied ? "Applied" : "Apply")
                        .frame(maxWidth: .infinity)
                }
                .oceannaButton(isPrimary: true)
                .disabled(hasApplied)
            }
        }
        .padding(OceannaTheme.Spacing.md)
        .background(OceannaTheme.Colors.secondaryBackground)
        .cornerRadius(OceannaTheme.Radius.sm)
    }

    private func expressInterest() {
        guard let userId = authService.userProfile?.id else { return }
        Task {
            try? await firestoreService.expressInterest(postId: postId, userId: userId)
            isInterested = true
        }
    }

    private func apply() {
        guard let userId = authService.userProfile?.id else { return }
        Task {
            try? await firestoreService.applyToOpportunity(postId: postId, userId: userId)
            hasApplied = true
        }
    }
}

#Preview {
    FeedView()
        .environmentObject(AuthService.shared)
}
