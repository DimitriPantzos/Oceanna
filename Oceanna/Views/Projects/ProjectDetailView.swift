import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showApplicants = false

    var isOwner: Bool {
        project.clientId == authViewModel.currentUser?.id
    }

    var hasApplied: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return project.applicants.contains(userId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        StatusBadge(status: project.status)

                        if project.isUrgent {
                            Label("Urgent", systemImage: "bolt.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                        }

                        Spacer()

                        Text("\(project.viewCount) views")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(project.title)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Divider()

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(icon: "folder", label: "Category", value: project.category)
                    DetailRow(icon: "dollarsign.circle", label: "Budget", value: project.budget.displayString)
                    DetailRow(icon: "calendar", label: "Timeline", value: project.timeline.displayString)
                    DetailRow(icon: "location", label: "Work Style", value: project.workStyle.rawValue)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)

                    Text(project.description)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)

                // Skills Required
                if !project.skills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skills Required")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(project.skills, id: \.self) { skill in
                                SkillTag(text: skill)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                // Applicants (for owner)
                if isOwner && !project.applicants.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Applicants")
                                .font(.headline)

                            Spacer()

                            Button("View All") {
                                showApplicants = true
                            }
                        }

                        Text("\(project.applicants.count) freelancer(s) interested")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                // Action Buttons
                if project.status == .open && !isOwner {
                    if hasApplied {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("You've applied to this project")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        Button {
                            applyToProject()
                        } label: {
                            Text("Apply Now")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if project.status == .draft {
                            Button("Publish", systemImage: "paperplane") {
                                Task { await viewModel.publishProject(project) }
                            }
                        }

                        if project.status == .open {
                            Button("Mark Complete", systemImage: "checkmark.circle") {
                                Task { await viewModel.closeProject(project) }
                            }
                        }

                        Button("Edit", systemImage: "pencil") { }

                        Button("Delete", systemImage: "trash", role: .destructive) { }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showApplicants) {
            ApplicantsView(project: project, viewModel: viewModel)
        }
    }

    private func applyToProject() {
        guard let userId = authViewModel.currentUser?.id else { return }
        Task {
            await viewModel.applyToProject(project, freelancerId: userId)
        }
    }
}

struct DetailRow: View {
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
                .fontWeight(.medium)
        }
    }
}

struct ApplicantsView: View {
    let project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @Environment(\.dismiss) var dismiss

    @State private var applicantProfiles: [FreelancerProfile] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            List {
                ForEach(applicantProfiles) { profile in
                    NavigationLink(destination: FreelancerDetailView(freelancerProfile: profile)) {
                        FreelancerListRow(freelancer: profile)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Hire") {
                            Task {
                                await viewModel.hireFreelancer(profile.userId, for: project)
                                dismiss()
                            }
                        }
                        .tint(.green)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Applicants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .task {
                await loadApplicants()
            }
        }
    }

    private func loadApplicants() async {
        // Load freelancer profiles for each applicant
        for applicantId in project.applicants {
            if let profile = try? await FirestoreService.shared.getFreelancerProfile(userId: applicantId) {
                applicantProfiles.append(profile)
            }
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: .example, viewModel: ProjectViewModel())
            .environmentObject(AuthViewModel())
    }
}
