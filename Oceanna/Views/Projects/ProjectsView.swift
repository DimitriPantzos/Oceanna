import SwiftUI

struct ProjectsView: View {
    @StateObject private var viewModel = ProjectViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showCreateProject = false
    @State private var selectedTab = 0

    var isClient: Bool {
        authViewModel.currentUser?.userType == .client
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector for clients
                if isClient {
                    Picker("View", selection: $selectedTab) {
                        Text("My Projects").tag(0)
                        Text("Browse").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }

                // Content
                if isClient && selectedTab == 0 {
                    ClientProjectsView(viewModel: viewModel)
                } else {
                    BrowseProjectsView(viewModel: viewModel)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                if isClient {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCreateProject = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateProject) {
                CreateProjectView(viewModel: viewModel)
            }
        }
    }
}

struct ClientProjectsView: View {
    @ObservedObject var viewModel: ProjectViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        List {
            if viewModel.clientProjects.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Projects Yet",
                    systemImage: "doc.text",
                    description: Text("Create your first project to find talented freelancers")
                )
            } else {
                ForEach(viewModel.clientProjects) { project in
                    NavigationLink(destination: ProjectDetailView(project: project, viewModel: viewModel)) {
                        ProjectRow(project: project)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.loadClientProjects(clientId: userId)
            }
        }
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.loadClientProjects(clientId: userId)
            }
        }
    }
}

struct BrowseProjectsView: View {
    @ObservedObject var viewModel: ProjectViewModel

    var body: some View {
        List {
            // Category filter
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(title: "All", isSelected: viewModel.categoryFilter == nil) {
                            viewModel.categoryFilter = nil
                            Task { await viewModel.loadOpenProjects() }
                        }

                        ForEach(DiscoveryViewModel.categories, id: \.self) { category in
                            FilterChip(title: category, isSelected: viewModel.categoryFilter == category) {
                                viewModel.categoryFilter = category
                                Task { await viewModel.loadOpenProjects(category: category) }
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Projects
            ForEach(viewModel.filteredProjects) { project in
                NavigationLink(destination: ProjectDetailView(project: project, viewModel: viewModel)) {
                    ProjectRow(project: project)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadOpenProjects()
        }
        .task {
            await viewModel.loadOpenProjects()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.projects.isEmpty {
                ContentUnavailableView(
                    "No Open Projects",
                    systemImage: "magnifyingglass",
                    description: Text("Check back later for new opportunities")
                )
            }
        }
    }
}

struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                StatusBadge(status: project.status)
            }

            Text(project.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Label(project.category, systemImage: "folder")

                Spacer()

                Text(project.budget.displayString)
                    .fontWeight(.medium)
            }
            .font(.caption)

            HStack {
                if project.isUrgent {
                    Label("Urgent", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Spacer()

                Text("\(project.applicants.count) applicants")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: Project.ProjectStatus

    var color: Color {
        switch status {
        case .draft: return .gray
        case .open: return .green
        case .inProgress: return .blue
        case .completed: return .purple
        case .cancelled: return .red
        case .onHold: return .orange
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

#Preview {
    ProjectsView()
        .environmentObject(AuthViewModel())
}
