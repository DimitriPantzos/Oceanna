import SwiftUI
import MapKit

struct DiscoveryView: View {
    @StateObject private var viewModel = DiscoveryViewModel()
    @StateObject private var locationService = LocationService.shared

    @State private var showFilters = false
    @State private var viewMode: ViewMode = .map
    @State private var showSwipeMode = false

    enum ViewMode: String, CaseIterable {
        case map = "Map"
        case list = "List"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main Content
                if viewMode == .map {
                    MapDiscoveryView(viewModel: viewModel)
                } else {
                    ListDiscoveryView(viewModel: viewModel)
                }

                // Floating controls
                VStack {
                    Spacer()

                    HStack {
                        // Location button
                        Button {
                            viewModel.centerOnUserLocation()
                        } label: {
                            Image(systemName: "location.fill")
                                .padding(12)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }

                        Spacer()

                        // Swipe mode button
                        Button {
                            showSwipeMode = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.stack.fill")
                                Text("Swipe")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(24)
                            .shadow(radius: 2)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .principal) {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showSwipeMode) {
                SwipeDiscoveryView(viewModel: viewModel)
            }
            .task {
                locationService.requestPermission()
                await viewModel.loadNearbyFreelancers()
            }
        }
    }
}

struct MapDiscoveryView: View {
    @ObservedObject var viewModel: DiscoveryViewModel

    var body: some View {
        Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.freelancers) { freelancer in
            MapAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: 37.7749 + Double.random(in: -0.05...0.05), // Mock coordinates
                longitude: -122.4194 + Double.random(in: -0.05...0.05)
            )) {
                FreelancerMapPin(freelancer: freelancer, isSelected: viewModel.selectedFreelancer?.id == freelancer.id) {
                    viewModel.selectFreelancer(freelancer)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .bottom) {
            if let selected = viewModel.selectedFreelancer {
                FreelancerPreviewCard(freelancer: selected) {
                    viewModel.clearSelection()
                }
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(), value: viewModel.selectedFreelancer?.id)
    }
}

struct FreelancerMapPin: View {
    let freelancer: FreelancerProfile
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(radius: 2)

                    Image(systemName: categoryIcon)
                        .foregroundColor(isSelected ? .white : .blue)
                }

                Image(systemName: "triangle.fill")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .blue : .white)
                    .rotationEffect(.degrees(180))
                    .offset(y: -6)
            }
        }
    }

    var categoryIcon: String {
        switch freelancer.categories.first {
        case "Design": return "paintbrush.fill"
        case "Development": return "chevron.left.forwardslash.chevron.right"
        case "Photography": return "camera.fill"
        case "Video": return "video.fill"
        case "Music & Audio": return "music.note"
        case "Writing": return "pencil"
        default: return "person.fill"
        }
    }
}

struct FreelancerPreviewCard: View {
    let freelancer: FreelancerProfile
    let onDismiss: () -> Void

    var body: some View {
        NavigationLink(destination: FreelancerDetailView(freelancerProfile: freelancer)) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Freelancer")
                        .font(.headline)

                    if !freelancer.skills.isEmpty {
                        Text(freelancer.skills.prefix(3).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", freelancer.rating))
                            .font(.caption)
                        Text("(\(freelancer.reviewCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let rate = freelancer.hourlyRate {
                            Text("$\(Int(rate))/hr")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)
        }
        .buttonStyle(.plain)
    }
}

struct ListDiscoveryView: View {
    @ObservedObject var viewModel: DiscoveryViewModel

    var body: some View {
        List {
            ForEach(viewModel.freelancers) { freelancer in
                NavigationLink(destination: FreelancerDetailView(freelancerProfile: freelancer)) {
                    FreelancerListRow(freelancer: freelancer)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadNearbyFreelancers()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.freelancers.isEmpty {
                ContentUnavailableView(
                    "No Freelancers Found",
                    systemImage: "person.3",
                    description: Text("Try expanding your search radius or adjusting filters")
                )
            }
        }
    }
}

struct FreelancerListRow: View {
    let freelancer: FreelancerProfile

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Freelancer")
                        .font(.headline)

                    if freelancer.availability.isAvailable {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(freelancer.skills.prefix(2).joined(separator: " | "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Label(String(format: "%.1f", freelancer.rating), systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    if let rate = freelancer.hourlyRate {
                        Text("$\(Int(rate))/hr")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DiscoveryView()
}
