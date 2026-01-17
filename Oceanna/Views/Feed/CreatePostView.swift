import SwiftUI

struct CreatePostView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var firestoreService = FirestoreService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var postType: PostType = .portfolio
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var newTag = ""

    // Opportunity fields
    @State private var budget = ""
    @State private var timeline = ""
    @State private var locationPreference: Availability = .both
    @State private var skillsNeeded: [String] = []
    @State private var newSkill = ""

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: OceannaTheme.Spacing.lg) {
                    // Post Type Selector
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
                        Text("Post Type")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: OceannaTheme.Spacing.xs) {
                                ForEach(PostType.allCases, id: \.self) { type in
                                    Button {
                                        postType = type
                                    } label: {
                                        HStack(spacing: OceannaTheme.Spacing.xxs) {
                                            Image(systemName: type.icon)
                                            Text(type.displayName)
                                        }
                                        .font(OceannaTheme.Typography.mono)
                                        .padding(.horizontal, OceannaTheme.Spacing.sm)
                                        .padding(.vertical, OceannaTheme.Spacing.xs)
                                        .background(postType == type ? OceannaTheme.Colors.primary : OceannaTheme.Colors.secondaryBackground)
                                        .foregroundColor(postType == type ? .white : OceannaTheme.Colors.primaryText)
                                        .cornerRadius(OceannaTheme.Radius.sm)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, OceannaTheme.Spacing.lg)

                    // Content
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
                        Text("Content")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        TextField("What's on your mind?", text: $content, axis: .vertical)
                            .textFieldStyle(OceannaTextFieldStyle())
                            .lineLimit(4...10)
                    }
                    .padding(.horizontal, OceannaTheme.Spacing.lg)

                    // Opportunity Details
                    if postType == .opportunity {
                        opportunityFields
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.sm) {
                        Text("Tags")
                            .font(OceannaTheme.Typography.headline)
                            .foregroundColor(OceannaTheme.Colors.primaryText)

                        HStack {
                            TextField("Add tag", text: $newTag)
                                .textFieldStyle(OceannaTextFieldStyle())

                            Button {
                                if !newTag.isEmpty {
                                    tags.append(newTag)
                                    newTag = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(OceannaTheme.Colors.primary)
                            }
                        }

                        FlowLayout(spacing: OceannaTheme.Spacing.xs) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: OceannaTheme.Spacing.xxs) {
                                    Text("#\(tag)")
                                    Button {
                                        tags.removeAll { $0 == tag }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10))
                                    }
                                }
                                .monoTag()
                            }
                        }
                    }
                    .padding(.horizontal, OceannaTheme.Spacing.lg)

                    if let error = errorMessage {
                        Text(error)
                            .font(OceannaTheme.Typography.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, OceannaTheme.Spacing.lg)
                    }
                }
                .padding(.vertical, OceannaTheme.Spacing.lg)
            }
            .background(OceannaTheme.Colors.background)
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(OceannaTheme.Colors.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createPost()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(OceannaTheme.Colors.primary)
                    .disabled(isLoading || content.isEmpty)
                }
            }
        }
    }

    private var opportunityFields: some View {
        VStack(alignment: .leading, spacing: OceannaTheme.Spacing.md) {
            Text("Opportunity Details")
                .font(OceannaTheme.Typography.headline)
                .foregroundColor(OceannaTheme.Colors.primaryText)

            TextField("Budget (e.g., $500-800)", text: $budget)
                .textFieldStyle(OceannaTextFieldStyle())

            TextField("Timeline (e.g., This weekend)", text: $timeline)
                .textFieldStyle(OceannaTextFieldStyle())

            VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xs) {
                Text("Location Preference")
                    .font(OceannaTheme.Typography.subheadline)
                    .foregroundColor(OceannaTheme.Colors.secondaryText)

                Picker("Location", selection: $locationPreference) {
                    ForEach(Availability.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xs) {
                Text("Skills Needed")
                    .font(OceannaTheme.Typography.subheadline)
                    .foregroundColor(OceannaTheme.Colors.secondaryText)

                HStack {
                    TextField("Add skill", text: $newSkill)
                        .textFieldStyle(OceannaTextFieldStyle())

                    Button {
                        if !newSkill.isEmpty {
                            skillsNeeded.append(newSkill)
                            newSkill = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(OceannaTheme.Colors.primary)
                    }
                }

                FlowLayout(spacing: OceannaTheme.Spacing.xs) {
                    ForEach(skillsNeeded, id: \.self) { skill in
                        HStack(spacing: OceannaTheme.Spacing.xxs) {
                            Text(skill)
                            Button {
                                skillsNeeded.removeAll { $0 == skill }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                            }
                        }
                        .monoTag()
                    }
                }
            }
        }
        .padding(.horizontal, OceannaTheme.Spacing.lg)
    }

    private func createPost() {
        guard let authorId = authService.userProfile?.id else { return }

        isLoading = true
        errorMessage = nil

        var opportunityDetails: OpportunityDetails? = nil
        if postType == .opportunity {
            opportunityDetails = OpportunityDetails(
                budget: budget.isEmpty ? nil : budget,
                timeline: timeline.isEmpty ? nil : timeline,
                locationPreference: locationPreference,
                skillsNeeded: skillsNeeded
            )
        }

        let post = FeedPost(
            authorId: authorId,
            postType: postType,
            content: content,
            tags: tags,
            opportunityDetails: opportunityDetails
        )

        Task {
            do {
                _ = try await firestoreService.createPost(post)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    CreatePostView()
        .environmentObject(AuthService.shared)
}
