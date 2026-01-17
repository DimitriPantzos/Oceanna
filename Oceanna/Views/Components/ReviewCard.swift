import SwiftUI

struct ReviewCard: View {
    let review: Review
    @StateObject private var firestoreService = FirestoreService.shared
    @State private var reviewer: User?

    var body: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
            // Header
            HStack(spacing: OceannaTheme.Spacing.sm) {
                if let reviewer = reviewer {
                    AvatarView(url: reviewer.avatarUrl, initials: reviewer.initials, size: 36)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(reviewer.displayName)
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        Text(review.createdAt, style: .date)
                            .font(OceannaTheme.Typography.caption)
                            .foregroundColor(OceannaTheme.Colors.tertiaryText)
                    }
                }

                Spacer()

                // Average rating
                HStack(spacing: OceannaTheme.Spacing.xxs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text(String(format: "%.1f", review.averageRating))
                        .font(OceannaTheme.Typography.mono)
                }
                .foregroundColor(OceannaTheme.Colors.primaryText)
            }

            // Category ratings
            HStack(spacing: OceannaTheme.Spacing.md) {
                CategoryRating(label: "Quality", rating: review.qualityRating)
                CategoryRating(label: "Communication", rating: review.communicationRating)
                CategoryRating(label: "Timeliness", rating: review.timelinessRating)
            }

            // Content
            if let content = review.content {
                Text(content)
                    .font(OceannaTheme.Typography.body)
                    .foregroundColor(OceannaTheme.Colors.secondaryText)
            }

            // Verified badge
            HStack(spacing: OceannaTheme.Spacing.xxs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                Text("Verified")
                    .font(OceannaTheme.Typography.monoSmall)
            }
            .foregroundColor(OceannaTheme.Colors.tertiaryText)
        }
        .padding(OceannaTheme.Spacing.md)
        .background(OceannaTheme.Colors.secondaryBackground)
        .cornerRadius(OceannaTheme.Radius.md)
        .task {
            do {
                reviewer = try await firestoreService.fetchUser(id: review.reviewerId)
            } catch {
                print("Error fetching reviewer: \(error)")
            }
        }
    }
}

struct CategoryRating: View {
    let label: String
    let rating: Int

    var body: some View {
        VStack(spacing: OceannaTheme.Spacing.xxs) {
            Text("\(rating)")
                .font(OceannaTheme.Typography.headline)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            Text(label)
                .font(OceannaTheme.Typography.monoSmall)
                .foregroundColor(OceannaTheme.Colors.tertiaryText)
        }
    }
}

#Preview {
    ReviewCard(review: Review.example)
        .padding()
}
