import SwiftUI

struct SwipeDiscoveryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DiscoveryViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Finding creatives near you...")
                } else if let profile = viewModel.currentSwipeProfile {
                    VStack {
                        // Card Stack
                        ZStack {
                            // Background cards
                            ForEach(Array(viewModel.swipeProfiles.dropFirst(viewModel.currentSwipeIndex + 1).prefix(2).enumerated()), id: \.element.id) { index, _ in
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemBackground))
                                    .frame(height: 500)
                                    .padding(.horizontal, CGFloat(30 + index * 10))
                                    .offset(y: CGFloat(index * 10))
                            }

                            // Current card
                            SwipeCard(freelancer: profile)
                                .offset(offset)
                                .rotationEffect(.degrees(rotation))
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            offset = gesture.translation
                                            rotation = Double(gesture.translation.width / 20)
                                        }
                                        .onEnded { gesture in
                                            handleSwipeEnd(translation: gesture.translation)
                                        }
                                )
                                .overlay(alignment: .topLeading) {
                                    if offset.width < -50 {
                                        Text("SKIP")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                            .padding()
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.red, lineWidth: 3)
                                            )
                                            .rotationEffect(.degrees(-15))
                                            .padding(30)
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    if offset.width > 50 {
                                        Text("CONNECT")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .padding()
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.green, lineWidth: 3)
                                            )
                                            .rotationEffect(.degrees(15))
                                            .padding(30)
                                    }
                                }
                        }
                        .padding()

                        // Action Buttons
                        HStack(spacing: 40) {
                            SwipeButton(icon: "xmark", color: .red) {
                                swipeLeft()
                            }

                            SwipeButton(icon: "star.fill", color: .yellow) {
                                // Super like / Save
                            }

                            SwipeButton(icon: "checkmark", color: .green) {
                                swipeRight()
                            }
                        }
                        .padding(.bottom, 30)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No more profiles")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Check back later or expand your search radius")
                            .foregroundColor(.secondary)

                        Button("Refresh") {
                            Task {
                                if let user = authViewModel.currentUser {
                                    await viewModel.loadSwipeProfiles(for: user)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                if let user = authViewModel.currentUser {
                    await viewModel.loadSwipeProfiles(for: user)
                }
            }
        }
    }

    private func handleSwipeEnd(translation: CGSize) {
        if translation.width > 150 {
            swipeRight()
        } else if translation.width < -150 {
            swipeLeft()
        } else {
            withAnimation(.spring()) {
                offset = .zero
                rotation = 0
            }
        }
    }

    private func swipeRight() {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: 500, height: 0)
            rotation = 15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let profile = viewModel.currentSwipeProfile {
                viewModel.swipeRight(on: profile)
            }
            offset = .zero
            rotation = 0
        }
    }

    private func swipeLeft() {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: -500, height: 0)
            rotation = -15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.swipeLeft()
            offset = .zero
            rotation = 0
        }
    }
}

struct SwipeCard: View {
    let freelancer: FreelancerProfile

    var body: some View {
        VStack(spacing: 0) {
            // Image placeholder
            Rectangle()
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 300)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.5))
                )

            // Info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Creative Professional")
                        .font(.title2)
                        .fontWeight(.bold)

                    if freelancer.availability.isAvailable {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                    }
                }

                // Rating and rate
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", freelancer.rating))
                        Text("(\(freelancer.reviewCount))")
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let rate = freelancer.hourlyRate {
                        Text("$\(Int(rate))/hr")
                            .fontWeight(.semibold)
                    }
                }
                .font(.subheadline)

                // Skills
                if !freelancer.skills.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(freelancer.skills.prefix(5), id: \.self) { skill in
                            Text(skill)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                }

                // Experience
                HStack {
                    if let years = freelancer.yearsOfExperience {
                        Label("\(years) years exp.", systemImage: "briefcase")
                    }

                    Label("\(freelancer.completedProjects) projects", systemImage: "checkmark.circle")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct SwipeButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(Color(.systemBackground))
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
}

#Preview {
    SwipeDiscoveryView(viewModel: DiscoveryViewModel())
        .environmentObject(AuthViewModel())
}
