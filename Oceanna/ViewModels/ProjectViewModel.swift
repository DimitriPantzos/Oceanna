import Foundation

@MainActor
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var clientProjects: [Project] = []
    @Published var appliedProjects: [Project] = []
    @Published var selectedProject: Project?
    @Published var projectMatches: [MatchingService.MatchScore] = []
    @Published var recommendedProjects: [MatchingService.ProjectRecommendation] = []

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private let matchingService = MatchingService.shared

    // MARK: - Load Projects

    func loadOpenProjects(category: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            projects = try await firestoreService.getOpenProjects(category: category)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadClientProjects(clientId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            clientProjects = try await firestoreService.getClientProjects(clientId: clientId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadProject(id: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            selectedProject = try await firestoreService.getProject(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create/Update Project

    func createProject(_ project: Project) async -> String? {
        isSaving = true
        defer { isSaving = false }

        do {
            let projectId = try await firestoreService.createProject(project)
            var newProject = project
            newProject.id = projectId
            clientProjects.insert(newProject, at: 0)
            return projectId
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func updateProject(_ project: Project) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await firestoreService.updateProject(project)
            if let index = clientProjects.firstIndex(where: { $0.id == project.id }) {
                clientProjects[index] = project
            }
            if selectedProject?.id == project.id {
                selectedProject = project
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func publishProject(_ project: Project) async {
        var updatedProject = project
        updatedProject.status = .open
        updatedProject.updatedAt = Date()
        await updateProject(updatedProject)
    }

    func closeProject(_ project: Project) async {
        var updatedProject = project
        updatedProject.status = .completed
        updatedProject.updatedAt = Date()
        await updateProject(updatedProject)
    }

    // MARK: - Applications

    func applyToProject(_ project: Project, freelancerId: String) async {
        guard let projectId = project.id else { return }

        do {
            try await firestoreService.applyToProject(projectId: projectId, freelancerId: freelancerId)

            // Update local state
            if let index = projects.firstIndex(where: { $0.id == projectId }) {
                projects[index].applicants.append(freelancerId)
            }
            if selectedProject?.id == projectId {
                selectedProject?.applicants.append(freelancerId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func hasApplied(_ project: Project, freelancerId: String) -> Bool {
        project.applicants.contains(freelancerId)
    }

    func hireFreelancer(_ freelancerId: String, for project: Project) async {
        var updatedProject = project
        updatedProject.hiredFreelancerId = freelancerId
        updatedProject.status = .inProgress
        updatedProject.updatedAt = Date()
        await updateProject(updatedProject)
    }

    // MARK: - Matching

    func findMatchingFreelancers(for project: Project) async {
        isLoading = true
        defer { isLoading = false }

        do {
            projectMatches = try await matchingService.findMatchingFreelancers(for: project)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func getRecommendedProjects(for freelancer: FreelancerProfile) async {
        isLoading = true
        defer { isLoading = false }

        do {
            recommendedProjects = try await matchingService.recommendProjects(for: freelancer)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filters

    @Published var categoryFilter: String?
    @Published var budgetFilter: Project.Budget.BudgetType?
    @Published var workStyleFilter: ProjectPreferences.WorkStyle?

    var filteredProjects: [Project] {
        var filtered = projects

        if let category = categoryFilter {
            filtered = filtered.filter { $0.category == category }
        }

        if let budgetType = budgetFilter {
            filtered = filtered.filter { $0.budget.type == budgetType }
        }

        if let workStyle = workStyleFilter {
            filtered = filtered.filter { $0.workStyle == workStyle }
        }

        return filtered
    }

    func clearFilters() {
        categoryFilter = nil
        budgetFilter = nil
        workStyleFilter = nil
    }
}
