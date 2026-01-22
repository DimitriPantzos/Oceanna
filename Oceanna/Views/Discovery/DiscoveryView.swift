import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = DiscoveryViewModel()

    private var isHireable: Bool {
        authViewModel.userProfile?.isHireable ?? true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OceannaTheme.Colors.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else if isHireable {
                    // Show opportunities
                    if viewModel.opportunities.isEmpty {
                        emptyOpportunitiesState
                    } else if viewModel.currentIndex < viewModel.opportunities.count {
                        opportunitySwipeView
                    } else {
                        noMoreCardsState
                    }
                } else {
                    // Show users
                    if viewModel.users.isEmpty {
                        emptyUsersState
                    } else if viewModel.currentIndex < viewModel.users.count {
                        userSwipeView
                    } else {
                        noMoreCardsState
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: OceannaTheme.Spacing.xs) {
                        Image(systemName: isHireable ? "briefcase" : "person.2")
                            .font(.system(size: 14))
                        Text(isHireable ? "Opportunities" : "People")
                            .font(OceannaTheme.Typography.mono)
                    }
                    .foregroundColor(OceannaTheme.Colors.secondaryText)
                }
            }
            .task {
                guard let userId = authViewModel.userProfile?.id else { return }
                await viewModel.loadContent(for: userId, isHireable: isHireable)
            }
        }
    }

    private var userSwipeView: some View {
        ZStack {
            ForEach(viewModel.users.indices.reversed(), id: \.self) { index in
                let user = viewModel.users[index]
                if index >= viewModel.currentIndex && index < viewModel.currentIndex + 3 {
                    SwipeCard(
                        content: {
                            UserCardContent(user: user)
                        },
                        onSwipeLeft: {
                            viewModel.nextCard()
                        },
                        onSwipeRight: {
                            sendConnectionRequest(to: user)
                        }
                    )
                    .offset(y: CGFloat(index - viewModel.currentIndex) * 8)
                    .scaleEffect(1 - CGFloat(index - viewModel.currentIndex) * 0.05)
                }
            }
        }
        .padding(.horizontal, OceannaTheme.Spacing.lg)
    }

    private var opportunitySwipeView: some View {
        ZStack {
            ForEach(viewModel.opportunities.indices.reversed(), id: \.self) { index in
                let opportunity = viewModel.opportunities[index]
                if index >= viewModel.currentIndex && index < viewModel.currentIndex + 3 {
                    if let author = viewModel.opportunityAuthors[opportunity.authorId] {
                        SwipeCard(
                            content: {
                                OpportunityCardContent(opportunity: opportunity, author: author)
                            },
                            onSwipeLeft: {
                                viewModel.nextCard()
                            },
                            onSwipeRight: {
                                applyToOpportunity(opportunity)
                            }
                        )
                        .offset(y: CGFloat(index - viewModel.currentIndex) * 8)
                        .scaleEffect(1 - CGFloat(index - viewModel.currentIndex) * 0.05)
                    }
                }
            }
        }
        .padding(.horizontal, OceannaTheme.Spacing.lg)
    }

    private var emptyUsersState: some View {
        VStack(spacing: OceannaTheme.Spacing.md) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(OceannaTheme.Colors.tertiaryText)

            Text("No one to discover")
                .font(OceannaTheme.Typography.headline)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            Text("Check back later for new creatives")
                .font(OceannaTheme.Typography.subheadline)
                .foregroundColor(OceannaTheme.Colors.secondaryText)
        }
    }

    private var emptyOpportunitiesState: some View {
        VStack(spacing: OceannaTheme.Spacing.md) {
            Image(systemName: "briefcase")
                .font(.system(size: 48))
                .foregroundColor(OceannaTheme.Colors.tertiaryText)

            Text("No opportunities yet")
                .font(OceannaTheme.Typography.headline)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            Text("Check back later for new opportunities")
                .font(OceannaTheme.Typography.subheadline)
                .foregroundColor(OceannaTheme.Colors.secondaryText)
        }
    }

    private var noMoreCardsState: some View {
        VStack(spacing: OceannaTheme.Spacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(OceannaTheme.Colors.tertiaryText)

            Text("You're all caught up!")
                .font(OceannaTheme.Typography.headline)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            Button("Refresh") {
                viewModel.refresh()
                Task {
                    guard let userId = authViewModel.userProfile?.id else { return }
                    await viewModel.loadContent(for: userId, isHireable: isHireable)
                }
            }
            .oceannaButton(isPrimary: false)
        }
    }

    private func sendConnectionRequest(to user: User) {
        guard let currentUserId = authViewModel.userProfile?.id,
              let targetUserId = user.id else { return }

        Task {
            await viewModel.sendConnectionRequest(to: targetUserId, from: currentUserId)
            viewModel.nextCard()
        }
    }

    private func applyToOpportunity(_ opportunity: FeedPost) {
        guard let userId = authViewModel.userProfile?.id,
              let postId = opportunity.id else { return }

        Task {
            await viewModel.applyToOpportunity(postId: postId, userId: userId)
            viewModel.nextCard()
        }
    }
}

struct SwipeCard<Content: View>: View {
    let content: () -> Content
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0

    private let swipeThreshold: CGFloat = 100

    init(
        @ViewBuilder content: @escaping () -> Content,
        onSwipeLeft: @escaping () -> Void,
        onSwipeRight: @escaping () -> Void
    ) {
        self.content = content
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
    }

    var body: some View {
        content()
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .opacity(opacity)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded { gesture in
                        if gesture.translation.width > swipeThreshold {
                            withAnimation(.easeOut(duration: 0.3)) {
                                offset = CGSize(width: 500, height: 0)
                                opacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipeRight()
                            }
                        } else if gesture.translation.width < -swipeThreshold {
                            withAnimation(.easeOut(duration: 0.3)) {
                                offset = CGSize(width: -500, height: 0)
                                opacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipeLeft()
                            }
                        } else {
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                    }
            )
    }
}

struct UserCardContent: View {
    let user: User

    var body: some View {
        VStack(spacing: 0) {
            // Image frame
            ZStack {
                if let url = user.avatarUrl, let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(OceannaTheme.Colors.secondaryBackground)
                    }
                } else {
                    Rectangle()
                        .fill(OceannaTheme.Colors.secondaryBackground)

                    Text(user.initials)
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(OceannaTheme.Colors.tertiaryText)
                }
            }
            .frame(height: 350)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
                Text(user.displayName)
                    .font(OceannaTheme.Typography.title3)
                    .foregroundColor(OceannaTheme.Colors.primaryText)

                if let skill = user.topSkill {
                    Text(skill)
                        .font(OceannaTheme.Typography.mono)
                        .foregroundColor(OceannaTheme.Colors.secondaryText)
                }

                if !user.city.isEmpty {
                    Text(user.city)
                        .font(OceannaTheme.Typography.caption)
                        .foregroundColor(OceannaTheme.Colors.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(OceannaTheme.Spacing.md)
        }
        .background(OceannaTheme.Colors.background)
        .cornerRadius(OceannaTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: OceannaTheme.Radius.lg)
                .stroke(OceannaTheme.Colors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

struct OpportunityCardContent: View {
    let opportunity: FeedPost
    let author: User

    var body: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.md) {
            // Author
            HStack(spacing: OceannaTheme.Spacing.sm) {
                AvatarView(url: author.avatarUrl, initials: author.initials, size: 40)

                VStack(alignment: .leading) {
                    Text(author.displayName)
                        .font(OceannaTheme.Typography.headline)
                        .foregroundColor(OceannaTheme.Colors.primaryText)

                    Text(author.city)
                        .font(OceannaTheme.Typography.caption)
                        .foregroundColor(OceannaTheme.Colors.tertiaryText)
                }
            }

            Divider()

            // Content
            Text(opportunity.content)
                .font(OceannaTheme.Typography.body)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            // Details
            if let details = opportunity.opportunityDetails {
                VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xs) {
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
            }

            Spacer()

            // Swipe hints
            HStack {
                HStack(spacing: OceannaTheme.Spacing.xxs) {
                    Image(systemName: "xmark")
                    Text("Pass")
                }
                .font(OceannaTheme.Typography.caption)
                .foregroundColor(OceannaTheme.Colors.tertiaryText)

                Spacer()

                HStack(spacing: OceannaTheme.Spacing.xxs) {
                    Text("Apply")
                    Image(systemName: "checkmark")
                }
                .font(OceannaTheme.Typography.caption)
                .foregroundColor(OceannaTheme.Colors.tertiaryText)
            }
        }
        .padding(OceannaTheme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 400)
        .background(OceannaTheme.Colors.background)
        .cornerRadius(OceannaTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: OceannaTheme.Radius.lg)
                .stroke(OceannaTheme.Colors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

#Preview {
    DiscoveryView()
        .environmentObject(AuthViewModel())
}
