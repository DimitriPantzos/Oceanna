import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if profileViewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let user = profileViewModel.user {
                    VStack(spacing: 24) {
                        // Profile Header
                        ProfileHeaderView(
                            user: user,
                            freelancerProfile: profileViewModel.freelancerProfile,
                            clientProfile: profileViewModel.clientProfile
                        )

                        // Profile Content based on user type
                        if user.userType == .freelancer {
                            FreelancerProfileContent(
                                profile: profileViewModel.freelancerProfile,
                                reviews: profileViewModel.reviews
                            )
                        } else {
                            ClientProfileContent(
                                profile: profileViewModel.clientProfile,
                                reviews: profileViewModel.reviews
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEditProfile = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }

                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }

                        Divider()

                        Button(role: .destructive) {
                            authViewModel.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: profileViewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task {
                await profileViewModel.loadCurrentUserProfile()
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    let freelancerProfile: FreelancerProfile?
    let clientProfile: ClientProfile?

    var rating: Double {
        freelancerProfile?.rating ?? clientProfile?.rating ?? 0
    }

    var reviewCount: Int {
        freelancerProfile?.reviewCount ?? clientProfile?.reviewCount ?? 0
    }

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            Text(user.initials)
                                .font(.title)
                                .foregroundColor(.blue)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(user.initials)
                            .font(.title)
                            .foregroundColor(.blue)
                    )
            }

            // Name and verification
            HStack(spacing: 8) {
                Text(user.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                if user.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                }
            }

            // Bio
            if let bio = user.bio {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Stats
            HStack(spacing: 24) {
                if rating > 0 {
                    StatView(value: String(format: "%.1f", rating), label: "Rating", icon: "star.fill")
                }

                StatView(value: "\(reviewCount)", label: "Reviews", icon: "text.bubble")

                if let freelancerProfile = freelancerProfile {
                    StatView(value: "\(freelancerProfile.completedProjects)", label: "Projects", icon: "checkmark.circle")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct StatView: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(value)
                    .font(.headline)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FreelancerProfileContent: View {
    let profile: FreelancerProfile?
    let reviews: [Review]

    var body: some View {
        VStack(spacing: 20) {
            // Skills
            if let profile = profile, !profile.skills.isEmpty {
                ProfileSection(title: "Skills") {
                    FlowLayout(spacing: 8) {
                        ForEach(profile.skills, id: \.self) { skill in
                            SkillTag(text: skill)
                        }
                    }
                }
            }

            // Services
            if let profile = profile, !profile.services.isEmpty {
                ProfileSection(title: "Services") {
                    ForEach(profile.services) { service in
                        ServiceCard(service: service)
                    }
                }
            }

            // Portfolio
            if let profile = profile, !profile.portfolio.isEmpty {
                ProfileSection(title: "Portfolio") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(profile.portfolio) { item in
                                PortfolioCard(item: item)
                            }
                        }
                    }
                }
            }

            // Reviews
            if !reviews.isEmpty {
                ProfileSection(title: "Reviews") {
                    ForEach(reviews.prefix(3)) { review in
                        ReviewCard(review: review)
                    }
                }
            }
        }
    }
}

struct ClientProfileContent: View {
    let profile: ClientProfile?
    let reviews: [Review]

    var body: some View {
        VStack(spacing: 20) {
            // Business Info
            if let profile = profile {
                ProfileSection(title: "Business Info") {
                    VStack(alignment: .leading, spacing: 12) {
                        if let businessName = profile.businessName {
                            InfoRow(icon: "building.2", label: "Business", value: businessName)
                        }
                        InfoRow(icon: "briefcase", label: "Type", value: profile.businessType.rawValue)
                        if let industry = profile.industry {
                            InfoRow(icon: "chart.pie", label: "Industry", value: industry)
                        }
                        if profile.isPaymentVerified {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                Text("Payment Verified")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }

            // Hiring Stats
            if let profile = profile {
                ProfileSection(title: "Hiring History") {
                    HStack(spacing: 24) {
                        StatView(value: "\(profile.totalProjectsPosted)", label: "Posted", icon: "doc.text")
                        StatView(value: "\(profile.totalHires)", label: "Hired", icon: "person.2")
                    }
                }
            }

            // Reviews
            if !reviews.isEmpty {
                ProfileSection(title: "Reviews from Freelancers") {
                    ForEach(reviews.prefix(3)) { review in
                        ReviewCard(review: review)
                    }
                }
            }
        }
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
