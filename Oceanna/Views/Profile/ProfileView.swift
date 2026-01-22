import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    private let firestoreService = FirestoreService.shared
    @State private var portfolio: [PortfolioItem] = []
    @State private var reviews: [Review] = []
    @State private var isLoading = true
    @State private var showingSettings = false
    @State private var showingEditProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let user = authViewModel.userProfile {
                    VStack(spacing: OceannaTheme.Spacing.lg) {
                        // Header
                        profileHeader(user: user)

                        // Hireable Toggle
                        hireableToggle(user: user)

                        // Skills
                        if !user.skills.isEmpty {
                            skillsSection(skills: user.skills)
                        }

                        // Portfolio
                        if !portfolio.isEmpty {
                            portfolioSection
                        }

                        // Reviews
                        if !reviews.isEmpty {
                            reviewsSection
                        }
                    }
                    .padding(.bottom, OceannaTheme.Spacing.xxl)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(OceannaTheme.Colors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditProfile = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(OceannaTheme.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                await loadData()
            }
        }
    }

    private func profileHeader(user: User) -> some View {
        VStack(spacing: OceannaTheme.Spacing.md) {
            // Avatar
            AvatarView(url: user.avatarUrl, initials: user.initials, size: 100)

            // Name & Location
            VStack(spacing: OceannaTheme.Spacing.xxs) {
                Text(user.displayName)
                    .font(OceannaTheme.Typography.title2)
                    .foregroundColor(OceannaTheme.Colors.primaryText)

                if !user.city.isEmpty {
                    Text(user.availabilityBadge)
                        .font(OceannaTheme.Typography.mono)
                        .foregroundColor(OceannaTheme.Colors.secondaryText)
                }
            }

            // Bio
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(OceannaTheme.Typography.body)
                    .foregroundColor(OceannaTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, OceannaTheme.Spacing.xl)
            }
        }
        .padding(.top, OceannaTheme.Spacing.lg)
    }

    private func hireableToggle(user: User) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xxs) {
                Text("Available for hire")
                    .font(OceannaTheme.Typography.headline)
                    .foregroundColor(OceannaTheme.Colors.primaryText)

                Text("Appear in discovery")
                    .font(OceannaTheme.Typography.caption)
                    .foregroundColor(OceannaTheme.Colors.secondaryText)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { user.isHireable },
                set: { newValue in
                    Task {
                        await authViewModel.updateHireableStatus(newValue)
                    }
                }
            ))
            .tint(OceannaTheme.Colors.primary)
        }
        .padding(OceannaTheme.Spacing.md)
        .background(OceannaTheme.Colors.secondaryBackground)
        .cornerRadius(OceannaTheme.Radius.md)
        .padding(.horizontal, OceannaTheme.Spacing.lg)
    }

    private func skillsSection(skills: [String]) -> some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
            Text("Skills")
                .font(OceannaTheme.Typography.headline)
                .foregroundColor(OceannaTheme.Colors.primaryText)
                .padding(.horizontal, OceannaTheme.Spacing.lg)

            FlowLayout(spacing: OceannaTheme.Spacing.xs) {
                ForEach(skills, id: \.self) { skill in
                    Text(skill)
                        .monoTag()
                }
            }
            .padding(.horizontal, OceannaTheme.Spacing.lg)
        }
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
            Text("Portfolio")
                .font(OceannaTheme.Typography.headline)
                .foregroundColor(OceannaTheme.Colors.primaryText)
                .padding(.horizontal, OceannaTheme.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: OceannaTheme.Spacing.md) {
                    ForEach(portfolio) { item in
                        PortfolioCard(item: item)
                    }
                }
                .padding(.horizontal, OceannaTheme.Spacing.lg)
            }
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
            Text("Reviews")
                .font(OceannaTheme.Typography.headline)
                .foregroundColor(OceannaTheme.Colors.primaryText)
                .padding(.horizontal, OceannaTheme.Spacing.lg)

            VStack(spacing: OceannaTheme.Spacing.md) {
                ForEach(reviews) { review in
                    ReviewCard(review: review)
                }
            }
            .padding(.horizontal, OceannaTheme.Spacing.lg)
        }
    }

    private func loadData() async {
        guard let userId = authViewModel.userProfile?.id else { return }

        do {
            portfolio = try await firestoreService.fetchPortfolio(for: userId)
            reviews = try await firestoreService.fetchReviews(for: userId)
        } catch {
            print("Error loading profile data: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
