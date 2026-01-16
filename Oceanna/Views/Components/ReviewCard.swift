import SwiftUI

struct ReviewCard: View {
    let review: Review

    @State private var reviewer: User?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(reviewer?.initials ?? "?")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(reviewer?.displayName ?? "User")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(formatDate(review.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Rating
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            // Title
            if let title = review.title {
                Text(title)
                    .font(.headline)
            }

            // Content
            Text(review.content)
                .font(.body)
                .foregroundColor(.secondary)

            // Category Ratings
            if !review.categories.isEmpty {
                HStack(spacing: 12) {
                    ForEach(review.categories, id: \.category) { categoryRating in
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", categoryRating.rating))
                                .font(.caption)
                                .fontWeight(.bold)
                            Text(categoryRating.category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Response
            if let response = review.response {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Response:")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text(response.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // Helpful
            HStack {
                Button {
                    // Mark as helpful
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                        Text("Helpful (\(review.helpfulCount))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .task {
            reviewer = try? await FirestoreService.shared.getUser(id: review.reviewerId)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    ReviewCard(review: .clientReviewExample)
        .padding()
}
