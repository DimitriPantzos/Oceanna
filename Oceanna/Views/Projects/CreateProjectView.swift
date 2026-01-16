import SwiftUI

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProjectViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var category = ""
    @State private var skills: [String] = []
    @State private var newSkill = ""

    // Budget
    @State private var budgetType: Project.Budget.BudgetType = .fixed
    @State private var budgetMin = ""
    @State private var budgetMax = ""

    // Timeline
    @State private var duration = ""
    @State private var isFlexible = true

    // Other
    @State private var workStyle: ProjectPreferences.WorkStyle = .flexible
    @State private var isUrgent = false
    @State private var publishImmediately = true

    var isValid: Bool {
        !title.isEmpty && !description.isEmpty && !category.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section {
                    TextField("Project Title", text: $title)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(5...10)

                    Picker("Category", selection: $category) {
                        Text("Select Category").tag("")
                        ForEach(DiscoveryViewModel.categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                } header: {
                    Text("Project Details")
                }

                // Skills
                Section {
                    ForEach(skills, id: \.self) { skill in
                        HStack {
                            Text(skill)
                            Spacer()
                            Button {
                                skills.removeAll { $0 == skill }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    HStack {
                        TextField("Add skill", text: $newSkill)
                        Button {
                            if !newSkill.isEmpty {
                                skills.append(newSkill)
                                newSkill = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newSkill.isEmpty)
                    }
                } header: {
                    Text("Required Skills")
                }

                // Budget
                Section {
                    Picker("Budget Type", selection: $budgetType) {
                        ForEach(Project.Budget.BudgetType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if budgetType != .negotiable {
                        HStack {
                            Text("$")
                            TextField("Min", text: $budgetMin)
                                .keyboardType(.numberPad)
                            Text("-")
                            TextField("Max", text: $budgetMax)
                                .keyboardType(.numberPad)
                            if budgetType == .hourly {
                                Text("/hr")
                            }
                        }
                    }
                } header: {
                    Text("Budget")
                }

                // Timeline
                Section {
                    TextField("Duration (e.g., '2-3 weeks')", text: $duration)
                    Toggle("Flexible Timeline", isOn: $isFlexible)
                } header: {
                    Text("Timeline")
                }

                // Work Style
                Section {
                    Picker("Work Style", selection: $workStyle) {
                        ForEach(ProjectPreferences.WorkStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }

                    Toggle("Mark as Urgent", isOn: $isUrgent)
                } header: {
                    Text("Preferences")
                }

                // Publish
                Section {
                    Toggle("Publish Immediately", isOn: $publishImmediately)
                } footer: {
                    Text(publishImmediately ? "Project will be visible to freelancers right away" : "Project will be saved as draft")
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(!isValid || viewModel.isSaving)
                }
            }
        }
    }

    private func createProject() {
        guard let clientId = authViewModel.currentUser?.id else { return }

        let budget = Project.Budget(
            min: Double(budgetMin),
            max: Double(budgetMax),
            type: budgetType
        )

        let timeline = Project.Timeline(
            duration: duration.isEmpty ? nil : duration,
            isFlexible: isFlexible
        )

        let project = Project(
            clientId: clientId,
            title: title,
            description: description,
            category: category,
            skills: skills,
            budget: budget,
            timeline: timeline,
            workStyle: workStyle,
            status: publishImmediately ? .open : .draft,
            isUrgent: isUrgent
        )

        Task {
            if let _ = await viewModel.createProject(project) {
                dismiss()
            }
        }
    }
}

#Preview {
    CreateProjectView(viewModel: ProjectViewModel())
        .environmentObject(AuthViewModel())
}
