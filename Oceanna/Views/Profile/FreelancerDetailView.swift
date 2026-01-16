import SwiftUI

struct FreelancerDetailView: View {
    let freelancerProfile: FreelancerProfile
    @State private var user: User?
    @State private var reviews: [Review] = []
    @State private var isLoading = true
    @State private var showMessageSheet = false

    @StateObject private var firestoreService = FirestoreService.shared

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else {
                VStack(spacing: 24) {
                    // Header
                    if let user = user {
                        ProfileHeaderView(
                            user: user,
                            freelancerProfile: freelancerProfile,
                            clientProfile: nil
                        )
                    }

                    // Quick Actions
                    HStack(spacing: 16) {
                        Button {
                            showMessageSheet = true
                        } label: {
                            Label("Message", systemImage: "message.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            // Save freelancer
                        } label: {
                            Label("Save", systemImage: "bookmark")
                        }
                        .buttonStyle(.bordered)
                    }

                    // Availability
                    AvailabilityCard(availability: freelancerProfile.availability)

                    // Details
                    FreelancerProfileContent(
                        profile: freelancerProfile,
                        reviews: reviews
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Freelancer")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
        .sheet(isPresented: $showMessageSheet) {
            // Message composer would go here
            Text("Send a message")
                .presentationDetents([.medium])
        }
    }

    private func loadData() async {
        do {
            user = try await firestoreService.getUser(id: freelancerProfile.userId)
            reviews = try await firestoreService.getReviews(for: freelancerProfile.userId)
            isLoading = false
        } catch {
            isLoading = false
        }
    }
}

struct AvailabilityCard: View {
    let availability: Availability

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(availability.isAvailable ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                Text(availability.isAvailable ? "Available for work" : "Not currently available")
                    .font(.headline)
            }

            if let hours = availability.hoursPerWeek {
                Text("Up to \(hours) hours/week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !availability.availableDays.isEmpty {
                HStack {
                    ForEach(0..<7) { day in
                        DayBadge(day: day, isAvailable: availability.availableDays.contains(day))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct DayBadge: View {
    let day: Int
    let isAvailable: Bool

    var dayLetter: String {
        ["S", "M", "T", "W", "T", "F", "S"][day]
    }

    var body: some View {
        Text(dayLetter)
            .font(.caption)
            .fontWeight(.medium)
            .frame(width: 32, height: 32)
            .background(isAvailable ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isAvailable ? .blue : .gray)
            .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        FreelancerDetailView(freelancerProfile: .example)
    }
}
